
# routers/admin_cliente_router.py
from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlmodel import Session
from typing import List, Optional
from datetime import datetime, timedelta
# En admin_cliente_router.py - actualizar imports
from Casos_de_uso.Usuarios.registrar_usuario import RegistrarUsuarioCase
from Casos_de_uso.Usuarios.editar_perfil import ModificarClienteAdminCase, ModificarClienteCase  # o ModificarClienteAdminCase
from Casos_de_uso.Usuarios.eliminar_cliente import EliminarClienteAdminCase

from database import get_session
from models.cliente import (
    Cliente, ClienteCreate, ClienteRead, ClienteUpdate, 
    LoginRequest, VerificacionResponse, ClienteStatsResponse
)
from Dominio.repositorios.repositorioCliente import RepositorioCliente
from Adaptadores.adaptadorClienteSQL import AdaptadorClienteSQL

admin_cliente_router = APIRouter(prefix="/api/admin/clientes", tags=["admin-clientes"])

def get_cliente_repository(session: Session = Depends(get_session)) -> RepositorioCliente:
    return AdaptadorClienteSQL(session)

@admin_cliente_router.get("/", response_model=List[ClienteRead])
def listar_todos_los_clientes(
    solo_activos: bool = Query(False, description="Filtrar solo clientes activos"),
    estado_membresia: Optional[str] = Query(None, description="Filtrar por estado de membresía"),
    fecha_registro_inicio: Optional[str] = Query(None, description="Fecha registro inicio (YYYY-MM-DD)"),
    fecha_registro_fin: Optional[str] = Query(None, description="Fecha registro fin (YYYY-MM-DD)"),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener todos los clientes (incluyendo inactivos) - Solo para administradores"""
    clientes = repository.listar_todos_los_usuarios()
    
    # Aplicar filtros
    if solo_activos:
        clientes = [cliente for cliente in clientes if cliente.activo]
    
    if estado_membresia:
        clientes = [cliente for cliente in clientes if cliente.estado_membresia == estado_membresia]
    
    if fecha_registro_inicio:
        try:
            fecha_ini = datetime.strptime(fecha_registro_inicio, "%Y-%m-%d")
            clientes = [cliente for cliente in clientes if cliente.fecha_registro >= fecha_ini]
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inicio inválido")
    
    if fecha_registro_fin:
        try:
            fecha_fin = datetime.strptime(fecha_registro_fin, "%Y-%m-%d") + timedelta(days=1)
            clientes = [cliente for cliente in clientes if cliente.fecha_registro < fecha_fin]
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha fin inválido")
    
    return clientes

@admin_cliente_router.get("/{cliente_id}", response_model=ClienteRead)
def obtener_cliente_detallado(
    cliente_id: int, 
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener un cliente con todos los detalles - Solo para administradores"""
    cliente = repository.consultar_usuario_por_id(cliente_id)
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cliente

@admin_cliente_router.get("/dni/{dni}/completo", response_model=ClienteRead)
def obtener_cliente_por_dni_completo(
    dni: str, 
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener un cliente por DNI con información completa - Solo para administradores"""
    cliente = repository.consultar_usuario_completo(dni)
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cliente

@admin_cliente_router.post("/", response_model=ClienteRead, status_code=status.HTTP_201_CREATED)
def crear_cliente_admin(
    cliente_data: ClienteCreate, 
    session: Session = Depends(get_session)
):
    """Crear un nuevo cliente - Solo para administradores"""
    caso_uso = RegistrarUsuarioCase(session)
    
    try:
        cliente_creado = caso_uso.ejecutar(cliente_data.dict())
        return cliente_creado
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear el cliente: {str(e)}")

@admin_cliente_router.post("/masivo", response_model=List[ClienteRead], status_code=status.HTTP_201_CREATED)
def crear_clientes_masivos(
    clientes_data: List[ClienteCreate],
    session: Session = Depends(get_session)
):
    """Crear múltiples clientes de forma masiva - Solo para administradores"""
    caso_uso = RegistrarUsuarioCase(session)
    clientes_creados = []
    
    for data in clientes_data:
        try:
            cliente_creado = caso_uso.ejecutar(data.dict())
            clientes_creados.append(cliente_creado)
        except Exception as e:
            raise HTTPException(
                status_code=400, 
                detail=f"Error al crear cliente {data.nombre}: {str(e)}"
            )
    
    return clientes_creados

@admin_cliente_router.put("/{cliente_id}", response_model=ClienteRead)
def actualizar_cliente_admin(
    cliente_id: int,
    cliente_data: ClienteUpdate,
    session: Session = Depends(get_session)
):
    """Actualizar un cliente existente - Solo para administradores"""
    caso_uso = ModificarClienteAdminCase(session)
    
    try:
        datos_actualizacion = cliente_data.dict(exclude_unset=True)
        cliente_actualizado = caso_uso.ejecutar(cliente_id, datos_actualizacion)
        return cliente_actualizado
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el cliente: {str(e)}")

@admin_cliente_router.put("/dni/{dni}", response_model=ClienteRead)
def actualizar_cliente_por_dni_admin(
    dni: str,
    cliente_data: ClienteUpdate,
    session: Session = Depends(get_session)
):
    """Actualizar un cliente por DNI - Solo para administradores"""
    caso_uso = ModificarClienteAdminCase(session)
    
    try:
        datos_actualizacion = cliente_data.dict(exclude_unset=True)
        cliente_actualizado = caso_uso.ejecutar_por_dni(dni, datos_actualizacion)
        return cliente_actualizado
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el cliente: {str(e)}")

@admin_cliente_router.patch("/{cliente_id}/activar", response_model=ClienteRead)
def activar_cliente_admin(
    cliente_id: int,
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Reactivar un cliente desactivado - Solo para administradores"""
    cliente_activado = repository.activar_usuario(cliente_id)
    if not cliente_activado:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cliente_activado

@admin_cliente_router.patch("/{cliente_id}/desactivar", response_model=ClienteRead)
def desactivar_cliente_admin(
    cliente_id: int,
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Desactivar un cliente - Solo para administradores"""
    cliente_desactivado = repository.desactivar_usuario(cliente_id)
    if not cliente_desactivado:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cliente_desactivado

@admin_cliente_router.patch("/{cliente_id}/membresia")
def actualizar_membresia_cliente(
    cliente_id: int,
    nuevo_estado: str = Query(..., description="Nuevo estado de membresía"),
    fecha_expiracion: Optional[str] = Query(None, description="Fecha expiración (YYYY-MM-DD)"),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Actualizar el estado de membresía de un cliente - Solo para administradores"""
    try:
        fecha_exp = None
        if fecha_expiracion:
            fecha_exp = datetime.strptime(fecha_expiracion, "%Y-%m-%d")
        
        cliente_actualizado = repository.actualizar_membresia(cliente_id, nuevo_estado, fecha_exp)
        if not cliente_actualizado:
            raise HTTPException(status_code=404, detail="Cliente no encontrado")
        
        return {
            "message": f"Membresía actualizada a '{nuevo_estado}'",
            "cliente": ClienteRead.from_orm(cliente_actualizado)
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@admin_cliente_router.delete("/{cliente_id}", status_code=status.HTTP_200_OK)
def eliminar_cliente_admin(
    cliente_id: int,
    session: Session = Depends(get_session)
):
    """Eliminar permanentemente un cliente - Solo para administradores"""
    caso_uso = EliminarClienteAdminCase(session)
    
    try:
        eliminado = caso_uso.ejecutar(cliente_id)
        if eliminado:
            return {"message": "Cliente eliminado permanentemente"}
        else:
            raise HTTPException(status_code=404, detail="Cliente no encontrado")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar el cliente: {str(e)}")

@admin_cliente_router.delete("/dni/{dni}", status_code=status.HTTP_200_OK)
def eliminar_cliente_por_dni_admin(
    dni: str,
    session: Session = Depends(get_session)
):
    """Eliminar permanentemente un cliente por DNI - Solo para administradores"""
    caso_uso = EliminarClienteAdminCase(session)
    
    try:
        eliminado = caso_uso.ejecutar_por_dni(dni)
        if eliminado:
            return {"message": "Cliente eliminado permanentemente"}
        else:
            raise HTTPException(status_code=404, detail="Cliente no encontrado")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar el cliente: {str(e)}")

@admin_cliente_router.delete("/batch/eliminar", status_code=status.HTTP_200_OK)
def eliminar_clientes_masivos(
    cliente_ids: List[int] = Query(..., description="Lista de IDs a eliminar"),
    session: Session = Depends(get_session)
):
    """Eliminar múltiples clientes de forma masiva - Solo para administradores"""
    caso_uso = EliminarClienteAdminCase(session)
    resultados = []
    
    for cliente_id in cliente_ids:
        try:
            eliminado = caso_uso.ejecutar(cliente_id)
            resultados.append({
                "id": cliente_id,
                "eliminado": eliminado,
                "mensaje": "Eliminado correctamente" if eliminado else "No encontrado"
            })
        except Exception as e:
            resultados.append({
                "id": cliente_id,
                "eliminado": False,
                "error": str(e)
            })
    
    return {
        "total_solicitados": len(cliente_ids),
        "eliminados_exitosos": len([r for r in resultados if r.get("eliminado")]),
        "detalles": resultados
    }

@admin_cliente_router.get("/estadisticas/totales", response_model=ClienteStatsResponse)
def obtener_estadisticas_clientes(
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener estadísticas de todos los clientes - Solo para administradores"""
    return repository.obtener_estadisticas_clientes()

@admin_cliente_router.get("/reporte/membresias")
def generar_reporte_membresias(
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Generar reporte de clientes por estado de membresía - Solo para administradores"""
    clientes = repository.listar_todos_los_usuarios()
    
    reporte = {}
    for cliente in clientes:
        estado = cliente.estado_membresia or "Sin membresía"
        if estado not in reporte:
            reporte[estado] = {
                "total": 0,
                "activos": 0,
                "inactivos": 0,
                "clientes": []
            }
        
        reporte[estado]["total"] += 1
        if cliente.activo:
            reporte[estado]["activos"] += 1
        else:
            reporte[estado]["inactivos"] += 1
        
        # Agregar cliente ejemplo (máximo 5 por estado)
        if len(reporte[estado]["clientes"]) < 5:
            reporte[estado]["clientes"].append({
                "id": cliente.id,
                "nombre": cliente.nombre,
                "dni": cliente.dni,
                "correo": cliente.correo,
                "fecha_registro": cliente.fecha_registro
            })
    
    return reporte

@admin_cliente_router.get("/reporte/registros")
def generar_reporte_registros(
    meses: int = Query(6, description="Número de meses a analizar"),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Generar reporte de registros por mes - Solo para administradores"""
    fecha_limite = datetime.now() - timedelta(days=meses*30)
    
    clientes = repository.listar_todos_los_usuarios()
    clientes_recientes = [c for c in clientes if c.fecha_registro >= fecha_limite]
    
    # Agrupar por mes
    registros_por_mes = {}
    for cliente in clientes_recientes:
        mes_key = cliente.fecha_registro.strftime("%Y-%m")
        if mes_key not in registros_por_mes:
            registros_por_mes[mes_key] = 0
        registros_por_mes[mes_key] += 1
    
    return {
        "periodo_meses": meses,
        "total_registros": len(clientes_recientes),
        "registros_por_mes": registros_por_mes,
        "promedio_mensual": round(len(clientes_recientes) / meses, 2) if meses > 0 else 0
    }

@admin_cliente_router.get("/buscar/avanzada")
def busqueda_avanzada_clientes(
    nombre: Optional[str] = Query(None),
    correo: Optional[str] = Query(None),
    dni: Optional[str] = Query(None),
    estado_membresia: Optional[str] = Query(None),
    activo: Optional[bool] = Query(None),
    fecha_registro_inicio: Optional[str] = Query(None),
    fecha_registro_fin: Optional[str] = Query(None),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Búsqueda avanzada de clientes - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_registro_inicio, "%Y-%m-%d") if fecha_registro_inicio else None
        fecha_fin = datetime.strptime(fecha_registro_fin, "%Y-%m-%d") if fecha_registro_fin else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    resultados = repository.busqueda_avanzada_clientes(
        nombre=nombre,
        correo=correo,
        dni=dni,
        estado_membresia=estado_membresia,
        activo=activo,
        fecha_registro_inicio=fecha_ini,
        fecha_registro_fin=fecha_fin
    )
    
    return {
        "parametros_busqueda": {
            "nombre": nombre,
            "correo": correo,
            "dni": dni,
            "estado_membresia": estado_membresia,
            "activo": activo,
            "fecha_registro_inicio": fecha_registro_inicio,
            "fecha_registro_fin": fecha_registro_fin
        },
        "total_resultados": len(resultados),
        "resultados": resultados
    }

@admin_cliente_router.get("/membresias/expiracion-proxima")
def obtener_membresias_expiracion_proxima(
    dias_antes: int = Query(7, description="Días antes de la expiración para alertar"),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener clientes con membresías que expirarán pronto - Solo para administradores"""
    alertas = repository.obtener_membresias_por_expiracion_proxima(dias_antes)
    
    return {
        "dias_antes_alerta": dias_antes,
        "total_alertas": len(alertas),
        "alertas": alertas
    }

@admin_cliente_router.patch("/batch/activar")
def activar_clientes_masivos(
    cliente_ids: List[int] = Query(..., description="Lista de IDs a activar"),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Activar múltiples clientes de forma masiva - Solo para administradores"""
    resultados = []
    
    for cliente_id in cliente_ids:
        try:
            cliente_activado = repository.activar_usuario(cliente_id)
            resultados.append({
                "id": cliente_id,
                "activado": cliente_activado is not None,
                "mensaje": "Activado correctamente" if cliente_activado else "No encontrado"
            })
        except Exception as e:
            resultados.append({
                "id": cliente_id,
                "activado": False,
                "error": str(e)
            })
    
    return {
        "total_solicitados": len(cliente_ids),
        "activados_exitosos": len([r for r in resultados if r.get("activado")]),
        "detalles": resultados
    }

@admin_cliente_router.patch("/batch/desactivar")
def desactivar_clientes_masivos(
    cliente_ids: List[int] = Query(..., description="Lista de IDs a desactivar"),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Desactivar múltiples clientes de forma masiva - Solo para administradores"""
    resultados = []
    
    for cliente_id in cliente_ids:
        try:
            cliente_desactivado = repository.desactivar_usuario(cliente_id)
            resultados.append({
                "id": cliente_id,
                "desactivado": cliente_desactivado is not None,
                "mensaje": "Desactivado correctamente" if cliente_desactivado else "No encontrado"
            })
        except Exception as e:
            resultados.append({
                "id": cliente_id,
                "desactivado": False,
                "error": str(e)
            })
    
    return {
        "total_solicitados": len(cliente_ids),
        "desactivados_exitosos": len([r for r in resultados if r.get("desactivado")]),
        "detalles": resultados
    }

@admin_cliente_router.get("/verificaciones/completas")
def verificaciones_completas(
    correo: Optional[str] = Query(None),
    dni: Optional[str] = Query(None),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Verificaciones completas de existencia - Solo para administradores"""
    resultado = {
        "correo_proporcionado": correo,
        "dni_proporcionado": dni,
        "verificaciones": {}
    }
    
    if correo:
        existe_correo = repository.autenticar_correo(correo)
        resultado["verificaciones"]["correo_existe"] = existe_correo
    
    if dni:
        cliente = repository.consultar_usuario(dni)
        resultado["verificaciones"]["dni_existe"] = cliente is not None
        if cliente:
            resultado["verificaciones"]["cliente_activo"] = cliente.activo
            resultado["verificaciones"]["estado_membresia"] = cliente.estado_membresia
    
    return resultado

@admin_cliente_router.get("/dashboard/estadisticas")
def obtener_dashboard_estadisticas(
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener estadísticas para el dashboard administrativo - Solo para administradores"""
    estadisticas = repository.obtener_estadisticas_dashboard()
    
    return {
        "resumen": estadisticas,
        "ultimos_registros": repository.obtener_ultimos_clientes_registrados(limit=10),
        "membresias_expiracion_proxima": repository.obtener_membresias_por_expiracion_proxima(7)
    }