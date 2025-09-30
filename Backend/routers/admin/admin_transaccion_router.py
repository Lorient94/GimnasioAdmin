# routers/admin_transaccion_router.py
from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlmodel import Session, select
from typing import List, Optional
from datetime import datetime, timedelta
import uuid

from database import get_session
from models.transaccion import (
    Transaccion, TransaccionCreate, TransaccionRead, TransaccionUpdate,
    TransaccionEstadoUpdate, TransaccionStatsResponse, MetodoPagoStats,
    EstadoPago, MetodoPago
)
from models.cliente import Cliente
from Adaptadores.adaptadorTransaccionSQL import AdaptadorTransaccionSQL
from Dominio.repositorios.repositorioTransaccion import RepositorioTransaccion

# Importar casos de uso
from Casos_de_uso.Transacciones.crear_transaccion import CrearTransaccionAdminCase
from Casos_de_uso.Transacciones.modificar_transaccion import ModificarTransaccionAdminCase
from Casos_de_uso.Transacciones.eliminar_transaccion import EliminarTransaccionAdminCase

admin_transaccion_router = APIRouter(prefix="/api/admin/transacciones", tags=["admin-transacciones"])

def get_repositorio_transacciones(session: Session = Depends(get_session)) -> RepositorioTransaccion:
    return AdaptadorTransaccionSQL(session)

@admin_transaccion_router.get("/", response_model=List[TransaccionRead])
def listar_todas_las_transacciones(
    estado: Optional[EstadoPago] = Query(None),
    cliente_dni: Optional[str] = Query(None),
    metodo_pago: Optional[MetodoPago] = Query(None),
    fecha_inicio: Optional[str] = Query(None, description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: Optional[str] = Query(None, description="Fecha fin (YYYY-MM-DD)"),
    monto_minimo: Optional[float] = Query(None, description="Monto mínimo"),
    monto_maximo: Optional[float] = Query(None, description="Monto máximo"),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener todas las transacciones (con filtros avanzados) - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d") if fecha_inicio else None
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d") if fecha_fin else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    transacciones = repositorio.listar_todas_las_transacciones()
    
    # Aplicar filtros adicionales
    if estado:
        transacciones = [t for t in transacciones if t.estado == estado]
    
    if cliente_dni:
        transacciones = [t for t in transacciones if t.cliente_dni == cliente_dni]
    
    if metodo_pago:
        transacciones = [t for t in transacciones if t.metodo_pago == metodo_pago]
    
    if fecha_ini:
        transacciones = [t for t in transacciones if t.fecha_creacion >= fecha_ini]
    
    if fecha_fin_dt:
        fecha_fin_dt = fecha_fin_dt + timedelta(days=1)
        transacciones = [t for t in transacciones if t.fecha_creacion < fecha_fin_dt]
    
    if monto_minimo is not None:
        transacciones = [t for t in transacciones if t.monto >= monto_minimo]
    
    if monto_maximo is not None:
        transacciones = [t for t in transacciones if t.monto <= monto_maximo]
    
    return sorted(transacciones, key=lambda x: x.fecha_creacion, reverse=True)

@admin_transaccion_router.get("/{transaccion_id}", response_model=TransaccionRead)
def obtener_transaccion_detallada(
    transaccion_id: int, 
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener una transacción con todos los detalles - Solo para administradores"""
    transaccion = repositorio.consultar_transaccion_completa(transaccion_id)
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    return transaccion

@admin_transaccion_router.get("/referencia/{referencia}/completo", response_model=TransaccionRead)
def obtener_transaccion_por_referencia_completo(
    referencia: str, 
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener una transacción por referencia con información completa - Solo para administradores"""
    transaccion = repositorio.consultar_transaccion_por_referencia_completa(referencia)
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    return transaccion

@admin_transaccion_router.post("/", response_model=TransaccionRead, status_code=status.HTTP_201_CREATED)
def crear_transaccion_admin(
    transaccion_data: TransaccionCreate, 
    session: Session = Depends(get_session)
):
    """Crear una nueva transacción - Solo para administradores"""
    caso_uso = CrearTransaccionAdminCase(session)
    
    try:
        # Generar referencia única si no se proporciona
        datos = transaccion_data.dict()
        if not datos.get('referencia'):
            datos['referencia'] = f"TRX-ADM-{uuid.uuid4().hex[:8].upper()}"
        
        transaccion_creada = caso_uso.ejecutar(datos)
        return transaccion_creada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear la transacción: {str(e)}")

@admin_transaccion_router.put("/{transaccion_id}", response_model=TransaccionRead)
def actualizar_transaccion_admin(
    transaccion_id: int,
    transaccion_data: TransaccionUpdate,
    session: Session = Depends(get_session)
):
    """Actualizar una transacción existente - Solo para administradores"""
    caso_uso = ModificarTransaccionAdminCase(session)
    
    try:
        datos_actualizacion = transaccion_data.dict(exclude_unset=True)
        transaccion_actualizada = caso_uso.ejecutar(transaccion_id, datos_actualizacion)
        return transaccion_actualizada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar la transacción: {str(e)}")

@admin_transaccion_router.patch("/{transaccion_id}/estado", response_model=TransaccionRead)
def cambiar_estado_transaccion_admin(
    transaccion_id: int,
    estado_data: TransaccionEstadoUpdate,
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Cambiar el estado de una transacción - Solo para administradores"""
    transaccion = repositorio.consultar_transaccion(transaccion_id)
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    # Validar cambio de estado
    if transaccion.estado == EstadoPago.COMPLETADO and estado_data.estado != EstadoPago.COMPLETADO:
        raise HTTPException(
            status_code=400, 
            detail="No se puede modificar el estado de una transacción completada"
        )
    
    if not repositorio.cambiar_estado_transaccion(
        transaccion_id, 
        estado_data.estado, 
        estado_data.observaciones
    ):
        raise HTTPException(status_code=500, detail="Error al cambiar el estado de la transacción")
    
    return repositorio.consultar_transaccion(transaccion_id)

@admin_transaccion_router.patch("/{transaccion_id}/marcar-como-pagada", response_model=TransaccionRead)
def marcar_como_pagada_admin(
    transaccion_id: int,
    referencia_pago: Optional[str] = Query(None, description="Referencia del pago"),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Marcar una transacción como pagada manualmente - Solo para administradores"""
    transaccion_actualizada = repositorio.marcar_como_pagada_manual(
        transaccion_id, 
        referencia_pago
    )
    if not transaccion_actualizada:
        raise HTTPException(status_code=404, detail="Transacción no encontrada o no se puede marcar como pagada")
    return transaccion_actualizada

@admin_transaccion_router.patch("/{transaccion_id}/revertir", response_model=TransaccionRead)
def revertir_transaccion_admin(
    transaccion_id: int,
    motivo: str = Query(..., description="Motivo de la reversión"),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Revertir una transacción completada - Solo para administradores"""
    transaccion_revertida = repositorio.revertir_transaccion(transaccion_id, motivo)
    if not transaccion_revertida:
        raise HTTPException(status_code=404, detail="Transacción no encontrada o no se puede revertir")
    return transaccion_revertida

@admin_transaccion_router.delete("/{transaccion_id}", status_code=status.HTTP_200_OK)
def eliminar_transaccion_admin(
    transaccion_id: int,
    session: Session = Depends(get_session)
):
    """Eliminar permanentemente una transacción - Solo para administradores"""
    caso_uso = EliminarTransaccionAdminCase(session)
    
    try:
        eliminada = caso_uso.ejecutar(transaccion_id)
        if eliminada:
            return {"message": "Transacción eliminada permanentemente"}
        else:
            raise HTTPException(status_code=404, detail="Transacción no encontrada")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar la transacción: {str(e)}")

@admin_transaccion_router.delete("/batch/eliminar", status_code=status.HTTP_200_OK)
def eliminar_transacciones_masivas(
    transaccion_ids: List[int] = Query(..., description="Lista de IDs a eliminar"),
    session: Session = Depends(get_session)
):
    """Eliminar múltiples transacciones de forma masiva - Solo para administradores"""
    caso_uso = EliminarTransaccionAdminCase(session)
    resultados = []
    
    for transaccion_id in transaccion_ids:
        try:
            eliminada = caso_uso.ejecutar(transaccion_id)
            resultados.append({
                "id": transaccion_id,
                "eliminada": eliminada,
                "mensaje": "Eliminada correctamente" if eliminada else "No encontrada"
            })
        except Exception as e:
            resultados.append({
                "id": transaccion_id,
                "eliminada": False,
                "error": str(e)
            })
    
    return {
        "total_solicitadas": len(transaccion_ids),
        "eliminadas_exitosas": len([r for r in resultados if r.get("eliminada")]),
        "detalles": resultados
    }

@admin_transaccion_router.get("/estadisticas/avanzadas", response_model=TransaccionStatsResponse)
def obtener_estadisticas_avanzadas(
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener estadísticas avanzadas de transacciones - Solo para administradores"""
    estadisticas = repositorio.obtener_estadisticas_avanzadas()
    return estadisticas

@admin_transaccion_router.get("/reporte/diario")
def generar_reporte_diario(
    fecha: str = Query(..., description="Fecha del reporte (YYYY-MM-DD)"),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Generar reporte diario de transacciones - Solo para administradores"""
    try:
        fecha_reporte = datetime.strptime(fecha, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    reporte = repositorio.generar_reporte_diario(fecha_reporte)
    
    return {
        "fecha": fecha_reporte,
        "resumen": reporte,
        "transacciones": repositorio.listar_transacciones_por_fecha(fecha_reporte)
    }

@admin_transaccion_router.get("/reporte/mensual")
def generar_reporte_mensual(
    año: int = Query(..., description="Año del reporte"),
    mes: int = Query(..., description="Mes del reporte (1-12)"),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Generar reporte mensual de transacciones - Solo para administradores"""
    if mes < 1 or mes > 12:
        raise HTTPException(status_code=400, detail="Mes debe estar entre 1 y 12")
    
    reporte = repositorio.generar_reporte_mensual(año, mes)
    
    return {
        "periodo": {"año": año, "mes": mes},
        "resumen": reporte
    }

@admin_transaccion_router.get("/reporte/metodos-pago/detallado")
def generar_reporte_metodos_pago_detallado(
    fecha_inicio: str = Query(..., description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: str = Query(..., description="Fecha fin (YYYY-MM-DD)"),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
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

@admin_transaccion_router.get("/cliente/{cliente_dni}/completo")
def obtener_transacciones_cliente_completo(
    cliente_dni: str,
    incluir_historicas: bool = Query(True, description="Incluir transacciones históricas"),
    limite: int = Query(100, description="Límite de transacciones a retornar"),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones),
    session: Session = Depends(get_session)
):
    """Obtener todas las transacciones de un cliente (completo) - Solo para administradores"""
    cliente = session.exec(select(Cliente).where(Cliente.dni == cliente_dni)).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    transacciones = repositorio.ver_historial_completo_cliente(cliente_dni, limite)
    
    if not incluir_historicas:
        # Filtrar solo transacciones recientes (últimos 6 meses)
        seis_meses_atras = datetime.now() - timedelta(days=180)
        transacciones = [t for t in transacciones if t.fecha_creacion >= seis_meses_atras]
    
    return {
        "cliente_dni": cliente_dni,
        "nombre_cliente": cliente.nombre,
        "total_transacciones": len(transacciones),
        "monto_total": sum(t.monto for t in transacciones if t.estado == EstadoPago.COMPLETADO),
        "transacciones": transacciones
    }

@admin_transaccion_router.get("/alertas/transacciones-pendientes")
def obtener_alertas_transacciones_pendientes(
    horas_limite: int = Query(24, description="Horas límite para considerar pendiente"),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener alertas de transacciones pendientes por mucho tiempo - Solo para administradores"""
    alertas = repositorio.obtener_transacciones_pendientes_antiguas(horas_limite)
    
    return {
        "horas_limite": horas_limite,
        "total_alertas": len(alertas),
        "alertas": alertas
    }

@admin_transaccion_router.get("/buscar/avanzada")
def busqueda_avanzada_transacciones(
    referencia: Optional[str] = Query(None),
    cliente_dni: Optional[str] = Query(None),
    estado: Optional[EstadoPago] = Query(None),
    metodo_pago: Optional[MetodoPago] = Query(None),
    monto_minimo: Optional[float] = Query(None),
    monto_maximo: Optional[float] = Query(None),
    fecha_inicio: Optional[str] = Query(None),
    fecha_fin: Optional[str] = Query(None),
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Búsqueda avanzada de transacciones - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d") if fecha_inicio else None
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d") if fecha_fin else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    resultados = repositorio.busqueda_avanzada(
        referencia=referencia,
        cliente_dni=cliente_dni,
        estado=estado,
        metodo_pago=metodo_pago,
        monto_minimo=monto_minimo,
        monto_maximo=monto_maximo,
        fecha_inicio=fecha_ini,
        fecha_fin=fecha_fin_dt
    )
    
    return {
        "parametros_busqueda": {
            "referencia": referencia,
            "cliente_dni": cliente_dni,
            "estado": estado.value if estado else None,
            "metodo_pago": metodo_pago.value if metodo_pago else None,
            "monto_minimo": monto_minimo,
            "monto_maximo": monto_maximo,
            "fecha_inicio": fecha_inicio,
            "fecha_fin": fecha_fin
        },
        "total_resultados": len(resultados),
        "resultados": resultados
    }

@admin_transaccion_router.get("/dashboard/estadisticas")
def obtener_dashboard_estadisticas(
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener estadísticas para el dashboard administrativo - Solo para administradores"""
    estadisticas = repositorio.obtener_estadisticas_dashboard()
    
    return {
        "resumen": estadisticas,
        "ultimas_transacciones": repositorio.obtener_ultimas_transacciones(limit=10),
        "alertas_pendientes": repositorio.obtener_transacciones_pendientes_antiguas(24)
    }