# routers/admin_pago_router.py
from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlmodel import Session, select
from typing import List, Optional
from datetime import datetime, timedelta
import uuid

from database import get_session
from models.pago import (
    Pago, PagoCreate, PagoRead, PagoUpdate, PagoEstadoUpdate,
    PagoStatsResponse, EstadoPago
)
from models.cliente import Cliente
from models.transaccion import Transaccion
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL
from Dominio.repositorios.repositorioPago import RepositorioPago

# Importar casos de uso
from Casos_de_uso.Pagos.crear_pago import CrearPagoAdminCase
from Casos_de_uso.Pagos.modificar_pago import ModificarPagoAdminCase
from Casos_de_uso.Pagos.eliminar_pago import EliminarPagoAdminCase
from Casos_de_uso.Pagos.procesar_pago_mercadopago import ProcesarPagoMercadoPagoCase
from Casos_de_uso.Pagos.verificar_estado_pago import VerificarEstadoPagoCase

admin_pago_router = APIRouter(prefix="/api/admin/pagos", tags=["admin-pagos"])

def get_repositorio_pagos(session: Session = Depends(get_session)) -> RepositorioPago:
    return AdaptadorPagoSQL(session)

@admin_pago_router.get("/", response_model=List[PagoRead])
def listar_todos_los_pagos(
    estado_pago: Optional[EstadoPago] = Query(None),
    id_usuario: Optional[str] = Query(None),
    transaccion_id: Optional[int] = Query(None),
    metodo_pago: Optional[str] = Query(None),
    fecha_inicio: Optional[str] = Query(None, description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: Optional[str] = Query(None, description="Fecha fin (YYYY-MM-DD)"),
    monto_minimo: Optional[float] = Query(None, description="Monto mínimo"),
    monto_maximo: Optional[float] = Query(None, description="Monto máximo"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener todos los pagos (con filtros avanzados) - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d") if fecha_inicio else None
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d") if fecha_fin else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    pagos = repositorio.listar_todos_los_pagos()
    
    # Aplicar filtros adicionales
    if estado_pago:
        pagos = [p for p in pagos if p.estado_pago == estado_pago]
    
    if id_usuario:
        pagos = [p for p in pagos if p.id_usuario == id_usuario]
    
    if transaccion_id:
        pagos = [p for p in pagos if p.transaccion_id == transaccion_id]
    
    if metodo_pago:
        pagos = [p for p in pagos if p.metodo_pago == metodo_pago]
    
    if fecha_ini:
        pagos = [p for p in pagos if p.fecha_creacion >= fecha_ini]
    
    if fecha_fin_dt:
        fecha_fin_dt = fecha_fin_dt + timedelta(days=1)
        pagos = [p for p in pagos if p.fecha_creacion < fecha_fin_dt]
    
    if monto_minimo is not None:
        pagos = [p for p in pagos if p.monto >= monto_minimo]
    
    if monto_maximo is not None:
        pagos = [p for p in pagos if p.monto <= monto_maximo]
    
    return sorted(pagos, key=lambda x: x.fecha_creacion, reverse=True)

@admin_pago_router.get("/{pago_id}", response_model=PagoRead)
def obtener_pago_detallado(
    pago_id: int, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener un pago con todos los detalles - Solo para administradores"""
    pago = repositorio.consultar_pago_completo(pago_id)
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    return pago

@admin_pago_router.get("/referencia/{referencia}/completo", response_model=PagoRead)
def obtener_pago_por_referencia_completo(
    referencia: str, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener un pago por referencia con información completa - Solo para administradores"""
    pago = repositorio.consultar_pago_por_referencia_completa(referencia)
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    return pago

@admin_pago_router.post("/", response_model=PagoRead, status_code=status.HTTP_201_CREATED)
def crear_pago_admin(
    pago_data: PagoCreate, 
    session: Session = Depends(get_session)
):
    """Crear un nuevo pago - Solo para administradores"""
    caso_uso = CrearPagoAdminCase(session)
    
    try:
        # Generar referencia única si no se proporciona
        datos = pago_data.dict()
        if not datos.get('referencia'):
            datos['referencia'] = f"PAGO-ADM-{uuid.uuid4().hex[:8].upper()}"
        
        pago_creado = caso_uso.ejecutar(datos)
        return pago_creado
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear el pago: {str(e)}")

@admin_pago_router.post("/manual", response_model=PagoRead, status_code=status.HTTP_201_CREATED)
def crear_pago_manual_admin(
    pago_data: PagoCreate, 
    session: Session = Depends(get_session)
):
    """Crear un pago manual (efectivo, transferencia, etc.) - Solo para administradores"""
    caso_uso = CrearPagoAdminCase(session)
    
    try:
        datos = pago_data.dict()
        if not datos.get('referencia'):
            datos['referencia'] = f"PAGO-MAN-{uuid.uuid4().hex[:8].upper()}"
        
        # Forzar estado completado para pagos manuales
        datos['estado_pago'] = EstadoPago.COMPLETADO
        
        pago_creado = caso_uso.ejecutar(datos)
        return pago_creado
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear el pago manual: {str(e)}")

@admin_pago_router.put("/{pago_id}", response_model=PagoRead)
def actualizar_pago_admin(
    pago_id: int,
    pago_data: PagoUpdate,
    session: Session = Depends(get_session)
):
    """Actualizar un pago existente - Solo para administradores"""
    caso_uso = ModificarPagoAdminCase(session)
    
    try:
        datos_actualizacion = pago_data.dict(exclude_unset=True)
        pago_actualizado = caso_uso.ejecutar(pago_id, datos_actualizacion)
        return pago_actualizado
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el pago: {str(e)}")

@admin_pago_router.patch("/{pago_id}/estado", response_model=PagoRead)
def cambiar_estado_pago_admin(
    pago_id: int,
    estado_data: PagoEstadoUpdate,
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Cambiar el estado de un pago - Solo para administradores"""
    pago = repositorio.consultar_pago(pago_id)
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    
    # Validar cambio de estado
    if pago.estado_pago == EstadoPago.COMPLETADO and estado_data.estado_pago != EstadoPago.COMPLETADO:
        raise HTTPException(
            status_code=400, 
            detail="No se puede modificar el estado de un pago completado"
        )
    
    if not repositorio.cambiar_estado_pago(
        pago_id, 
        estado_data.estado_pago, 
        estado_data.observaciones
    ):
        raise HTTPException(status_code=500, detail="Error al cambiar el estado del pago")
    
    return repositorio.consultar_pago(pago_id)

@admin_pago_router.patch("/{pago_id}/completar", response_model=PagoRead)
def completar_pago_admin(
    pago_id: int, 
    referencia_pago: Optional[str] = Query(None, description="Referencia del pago"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Marcar un pago como completado manualmente - Solo para administradores"""
    pago_completado = repositorio.completar_pago_manual(pago_id, referencia_pago)
    if not pago_completado:
        raise HTTPException(status_code=404, detail="Pago no encontrado o no se puede completar")
    return pago_completado

@admin_pago_router.patch("/{pago_id}/rechazar", response_model=PagoRead)
def rechazar_pago_admin(
    pago_id: int, 
    motivo: str = Query(..., description="Motivo del rechazo"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Marcar un pago como rechazado - Solo para administradores"""
    pago_rechazado = repositorio.rechazar_pago_manual(pago_id, motivo)
    if not pago_rechazado:
        raise HTTPException(status_code=404, detail="Pago no encontrado o no se puede rechazar")
    return pago_rechazado

@admin_pago_router.patch("/{pago_id}/reembolsar", response_model=PagoRead)
def reembolsar_pago_admin(
    pago_id: int, 
    motivo: str = Query(..., description="Motivo del reembolso"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Reembolsar un pago completado - Solo para administradores"""
    pago_reembolsado = repositorio.reembolsar_pago(pago_id, motivo)
    if not pago_reembolsado:
        raise HTTPException(status_code=404, detail="Pago no encontrado o no se puede reembolsar")
    return pago_reembolsado

@admin_pago_router.delete("/{pago_id}", status_code=status.HTTP_200_OK)
def eliminar_pago_admin(
    pago_id: int,
    session: Session = Depends(get_session)
):
    """Eliminar permanentemente un pago - Solo para administradores"""
    caso_uso = EliminarPagoAdminCase(session)
    
    try:
        eliminado = caso_uso.ejecutar(pago_id)
        if eliminado:
            return {"message": "Pago eliminado permanentemente"}
        else:
            raise HTTPException(status_code=404, detail="Pago no encontrado")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar el pago: {str(e)}")

@admin_pago_router.delete("/batch/eliminar", status_code=status.HTTP_200_OK)
def eliminar_pagos_masivos(
    pago_ids: List[int] = Query(..., description="Lista de IDs a eliminar"),
    session: Session = Depends(get_session)
):
    """Eliminar múltiples pagos de forma masiva - Solo para administradores"""
    caso_uso = EliminarPagoAdminCase(session)
    resultados = []
    
    for pago_id in pago_ids:
        try:
            eliminado = caso_uso.ejecutar(pago_id)
            resultados.append({
                "id": pago_id,
                "eliminado": eliminado,
                "mensaje": "Eliminado correctamente" if eliminado else "No encontrado"
            })
        except Exception as e:
            resultados.append({
                "id": pago_id,
                "eliminado": False,
                "error": str(e)
            })
    
    return {
        "total_solicitados": len(pago_ids),
        "eliminados_exitosos": len([r for r in resultados if r.get("eliminado")]),
        "detalles": resultados
    }

@admin_pago_router.get("/estadisticas/avanzadas", response_model=PagoStatsResponse)
def obtener_estadisticas_avanzadas(
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener estadísticas avanzadas de pagos - Solo para administradores"""
    estadisticas = repositorio.obtener_estadisticas_avanzadas()
    return estadisticas

@admin_pago_router.get("/reporte/diario")
def generar_reporte_diario(
    fecha: str = Query(..., description="Fecha del reporte (YYYY-MM-DD)"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Generar reporte diario de pagos - Solo para administradores"""
    try:
        fecha_reporte = datetime.strptime(fecha, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    reporte = repositorio.generar_reporte_diario(fecha_reporte)
    
    return {
        "fecha": fecha_reporte,
        "resumen": reporte,
        "pagos": repositorio.listar_pagos_por_fecha(fecha_reporte)
    }

@admin_pago_router.get("/reporte/mensual")
def generar_reporte_mensual(
    año: int = Query(..., description="Año del reporte"),
    mes: int = Query(..., description="Mes del reporte (1-12)"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Generar reporte mensual de pagos - Solo para administradores"""
    if mes < 1 or mes > 12:
        raise HTTPException(status_code=400, detail="Mes debe estar entre 1 y 12")
    
    reporte = repositorio.generar_reporte_mensual(año, mes)
    
    return {
        "periodo": {"año": año, "mes": mes},
        "resumen": reporte
    }

@admin_pago_router.get("/reporte/metodos-pago/detallado")
def generar_reporte_metodos_pago_detallado(
    fecha_inicio: str = Query(..., description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: str = Query(..., description="Fecha fin (YYYY-MM-DD)"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Generar reporte detallado por método de pago - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d")
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    reporte = repositorio.generar_reporte_metodos_pago_detallado(fecha_ini, fecha_fin_dt)
    
    return {
        "periodo": {"fecha_inicio": fecha_ini, "fecha_fin": fecha_fin_dt},
        "metodos_pago": reporte
    }

@admin_pago_router.get("/usuario/{usuario_dni}/completo")
def obtener_pagos_usuario_completo(
    usuario_dni: str,
    incluir_historicos: bool = Query(True, description="Incluir pagos históricos"),
    limite: int = Query(100, description="Límite de pagos a retornar"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos),
    session: Session = Depends(get_session)
):
    """Obtener todos los pagos de un usuario (completo) - Solo para administradores"""
    usuario = session.exec(select(Cliente).where(Cliente.dni == usuario_dni)).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    pagos = repositorio.obtener_historial_completo_usuario(usuario_dni, limite)
    
    if not incluir_historicos:
        # Filtrar solo pagos recientes (últimos 6 meses)
        seis_meses_atras = datetime.now() - timedelta(days=180)
        pagos = [p for p in pagos if p.fecha_creacion >= seis_meses_atras]
    
    return {
        "usuario_dni": usuario_dni,
        "nombre_usuario": usuario.nombre,
        "total_pagos": len(pagos),
        "monto_total": sum(p.monto for p in pagos if p.estado_pago == EstadoPago.COMPLETADO),
        "pagos": pagos
    }

@admin_pago_router.get("/transaccion/{transaccion_id}/completo")
def obtener_pagos_transaccion_completo(
    transaccion_id: int,
    repositorio: RepositorioPago = Depends(get_repositorio_pagos),
    session: Session = Depends(get_session)
):
    """Obtener todos los pagos de una transacción (completo) - Solo para administradores"""
    transaccion = session.get(Transaccion, transaccion_id)
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    pagos = repositorio.obtener_pagos_transaccion_completos(transaccion_id)
    
    return {
        "transaccion_id": transaccion_id,
        "monto_transaccion": transaccion.monto,
        "total_pagos": len(pagos),
        "monto_pagado": sum(p.monto for p in pagos if p.estado_pago == EstadoPago.COMPLETADO),
        "saldo_pendiente": transaccion.monto - sum(p.monto for p in pagos if p.estado_pago == EstadoPago.COMPLETADO),
        "pagos": pagos
    }

@admin_pago_router.get("/alertas/pagos-pendientes")
def obtener_alertas_pagos_pendientes(
    dias_limite: int = Query(3, description="Días límite para considerar pendiente"),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener alertas de pagos pendientes por mucho tiempo - Solo para administradores"""
    alertas = repositorio.obtener_pagos_pendientes_antiguos(dias_limite)
    
    return {
        "dias_limite": dias_limite,
        "total_alertas": len(alertas),
        "alertas": alertas
    }

@admin_pago_router.get("/buscar/avanzada")
def busqueda_avanzada_pagos(
    referencia: Optional[str] = Query(None),
    usuario_dni: Optional[str] = Query(None),
    estado_pago: Optional[EstadoPago] = Query(None),
    metodo_pago: Optional[str] = Query(None),
    monto_minimo: Optional[float] = Query(None),
    monto_maximo: Optional[float] = Query(None),
    fecha_inicio: Optional[str] = Query(None),
    fecha_fin: Optional[str] = Query(None),
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Búsqueda avanzada de pagos - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d") if fecha_inicio else None
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d") if fecha_fin else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    resultados = repositorio.busqueda_avanzada(
        referencia=referencia,
        usuario_dni=usuario_dni,
        estado_pago=estado_pago,
        metodo_pago=metodo_pago,
        monto_minimo=monto_minimo,
        monto_maximo=monto_maximo,
        fecha_inicio=fecha_ini,
        fecha_fin=fecha_fin_dt
    )
    
    return {
        "parametros_busqueda": {
            "referencia": referencia,
            "usuario_dni": usuario_dni,
            "estado_pago": estado_pago.value if estado_pago else None,
            "metodo_pago": metodo_pago,
            "monto_minimo": monto_minimo,
            "monto_maximo": monto_maximo,
            "fecha_inicio": fecha_inicio,
            "fecha_fin": fecha_fin
        },
        "total_resultados": len(resultados),
        "resultados": resultados
    }

@admin_pago_router.post("/{pago_id}/verificar-mercado-pago")
def verificar_pago_mercadopago_admin(
    pago_id: int,
    session: Session = Depends(get_session)
):
    """Verificar el estado de un pago de Mercado Pago - Solo para administradores"""
    caso_uso = VerificarEstadoPagoCase(session)
    
    try:
        resultado = caso_uso.ejecutar(pago_id)
        return resultado
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al verificar pago: {str(e)}")

@admin_pago_router.get("/dashboard/estadisticas")
def obtener_dashboard_estadisticas(
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener estadísticas para el dashboard administrativo - Solo para administradores"""
    estadisticas = repositorio.obtener_estadisticas_dashboard()
    
    return {
        "resumen": estadisticas,
        "ultimos_pagos": repositorio.obtener_ultimos_pagos(limit=10),
        "alertas_pendientes": repositorio.obtener_pagos_pendientes_antiguos(3)
    }