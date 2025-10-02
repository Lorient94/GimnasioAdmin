# routers/admin_inscripcion_router.py
from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlmodel import Session, select
from typing import List, Optional
from datetime import datetime, timedelta

from database import get_session
from models.inscripcion import (
    Inscripcion, InscripcionCreate, InscripcionRead, InscripcionUpdate,
    InscripcionCancelacion, InscripcionStatsResponse, EstadoInscripcion
)
from models.cliente import Cliente
from models.clase import Clase
from Adaptadores.adaptadorInscripcionSQL import AdaptadorInscripcionesSQL
from Dominio.repositorios.repositorioInscripciones import RepositorioInscripciones

# Importar casos de uso
from Casos_de_uso.Inscripciones.crear_inscripcion import CrearInscripcionAdminCase
from Casos_de_uso.Inscripciones.modificar_inscripcion import ModificarInscripcionAdminCase
from Casos_de_uso.Inscripciones.eliminar_inscripcion import EliminarInscripcionAdminCase

admin_inscripcion_router = APIRouter(prefix="/api/admin/inscripciones", tags=["admin-inscripciones"])

def get_repositorio_inscripciones(session: Session = Depends(get_session)) -> RepositorioInscripciones:
    return AdaptadorInscripcionesSQL(session)
def _parse_estado_inscripcion(valor: str) -> EstadoInscripcion:
    """Mapea variantes comunes de estado (activa/activo, cancelada/cancelado, completada/completado)
    a los valores del Enum EstadoInscripcion. Lanzará ValueError si no reconoce el valor.
    """
    v = valor.strip().lower()
    if v in ("activo", "activa"):
        return EstadoInscripcion.ACTIVO
    if v in ("cancelado", "cancelada"):
        return EstadoInscripcion.CANCELADO
    if v in ("pendiente",):
        return EstadoInscripcion.PENDIENTE
    if v in ("completado", "completada"):
        return EstadoInscripcion.COMPLETADO
    raise ValueError(f"Estado de inscripción desconocido: {valor}")


@admin_inscripcion_router.get("/", response_model=List[InscripcionRead])
def listar_todas_las_inscripciones(
    estado: Optional[str] = Query(None),
    cliente_dni: Optional[str] = Query(None),
    clase_id: Optional[int] = Query(None),
    solo_activas: bool = Query(False, description="Filtrar solo inscripciones activas"),
    fecha_inicio: Optional[str] = Query(None, description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: Optional[str] = Query(None, description="Fecha fin (YYYY-MM-DD)"),
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones),
    session: Session = Depends(get_session)
):
    """Obtener todas las inscripciones (incluyendo históricas) - Solo para administradores"""
    inscripciones = repositorio.listar_todas_las_inscripciones()
    
    # Aplicar filtros
    if estado:
        try:
            estado_enum = _parse_estado_inscripcion(estado)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        inscripciones = [ins for ins in inscripciones if ins.estado == estado_enum]
    
    if cliente_dni:
        inscripciones = [ins for ins in inscripciones if ins.cliente_dni == cliente_dni]
    
    if clase_id:
        inscripciones = [ins for ins in inscripciones if ins.clase_id == clase_id]
    
    if solo_activas:
        inscripciones = [ins for ins in inscripciones if ins.estado == EstadoInscripcion.ACTIVO]
    
    if fecha_inicio:
        try:
            fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d")
            inscripciones = [ins for ins in inscripciones if ins.fecha_inscripcion >= fecha_ini]
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inicio inválido")
    
    if fecha_fin:
        try:
            fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d") + timedelta(days=1)
            inscripciones = [ins for ins in inscripciones if ins.fecha_inscripcion < fecha_fin_dt]
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha fin inválido")
    
    return inscripciones

@admin_inscripcion_router.get("/{inscripcion_id}", response_model=InscripcionRead)
def obtener_inscripcion_detallada(
    inscripcion_id: int, 
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Obtener una inscripción con todos los detalles - Solo para administradores"""
    inscripcion = repositorio.consultar_inscripcion_completa(inscripcion_id)
    if not inscripcion:
        raise HTTPException(status_code=404, detail="Inscripción no encontrada")
    return inscripcion

@admin_inscripcion_router.post("/", response_model=InscripcionRead, status_code=status.HTTP_201_CREATED)
def crear_inscripcion_admin(
    inscripcion_data: InscripcionCreate, 
    session: Session = Depends(get_session)
):
    """Crear una nueva inscripción - Solo para administradores"""
    caso_uso = CrearInscripcionAdminCase(session)
    
    try:
        inscripcion_creada = caso_uso.ejecutar(inscripcion_data.dict())
        return inscripcion_creada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear la inscripción: {str(e)}")

@admin_inscripcion_router.put("/{inscripcion_id}", response_model=InscripcionRead)
def actualizar_inscripcion_admin(
    inscripcion_id: int,
    inscripcion_data: InscripcionUpdate,
    session: Session = Depends(get_session)
):
    """Actualizar una inscripción existente - Solo para administradores"""
    caso_uso = ModificarInscripcionAdminCase(session)
    
    try:
        datos_actualizacion = inscripcion_data.dict(exclude_unset=True)
        inscripcion_actualizada = caso_uso.ejecutar(inscripcion_id, datos_actualizacion)
        return inscripcion_actualizada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar la inscripción: {str(e)}")

@admin_inscripcion_router.patch("/{inscripcion_id}/cancelar", response_model=InscripcionRead)
def cancelar_inscripcion_admin(
    inscripcion_id: int,
    cancelacion_data: InscripcionCancelacion,
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Cancelar una inscripción - Solo para administradores"""
    inscripcion = repositorio.consultar_inscripcion(inscripcion_id)
    if not inscripcion:
        raise HTTPException(status_code=404, detail="Inscripción no encontrada")
    
    if inscripcion.estado == EstadoInscripcion.CANCELADO:
        raise HTTPException(status_code=400, detail="La inscripción ya está cancelada")
    
    try:
        resultado = repositorio.cancelar_inscripcion(inscripcion_id, cancelacion_data.motivo)
        return repositorio.consultar_inscripcion(inscripcion_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al cancelar inscripción: {str(e)}")

@admin_inscripcion_router.patch("/{inscripcion_id}/reactivar", response_model=InscripcionRead)
def reactivar_inscripcion_admin(
    inscripcion_id: int,
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Reactivar una inscripción cancelada - Solo para administradores"""
    inscripcion_reactivada = repositorio.reactivar_inscripcion(inscripcion_id)
    if not inscripcion_reactivada:
        raise HTTPException(status_code=404, detail="Inscripción no encontrada o no se puede reactivar")
    return inscripcion_reactivada

@admin_inscripcion_router.patch("/{inscripcion_id}/completar", response_model=InscripcionRead)
def completar_inscripcion_admin(
    inscripcion_id: int, 
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Marcar una inscripción como completada - Solo para administradores"""
    inscripcion = repositorio.consultar_inscripcion(inscripcion_id)
    if not inscripcion:
        raise HTTPException(status_code=404, detail="Inscripción no encontrada")
    
    if inscripcion.estado == EstadoInscripcion.COMPLETADO:
        raise HTTPException(status_code=400, detail="La inscripción ya está completada")
    
    if not repositorio.completar_inscripcion(inscripcion_id):
        raise HTTPException(status_code=500, detail="Error al completar la inscripción")
    
    return repositorio.consultar_inscripcion(inscripcion_id)

@admin_inscripcion_router.delete("/{inscripcion_id}", status_code=status.HTTP_200_OK)
def eliminar_inscripcion_admin(
    inscripcion_id: int,
    session: Session = Depends(get_session)
):
    """Eliminar permanentemente una inscripción - Solo para administradores"""
    caso_uso = EliminarInscripcionAdminCase(session)
    
    try:
        eliminada = caso_uso.ejecutar(inscripcion_id)
        if eliminada:
            return {"message": "Inscripción eliminada permanentemente"}
        else:
            raise HTTPException(status_code=404, detail="Inscripción no encontrada")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar la inscripción: {str(e)}")

@admin_inscripcion_router.get("/estadisticas/avanzadas", response_model=InscripcionStatsResponse)
def obtener_estadisticas_avanzadas(
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Obtener estadísticas avanzadas de inscripciones - Solo para administradores"""
    estadisticas = repositorio.obtener_estadisticas_avanzadas()
    return estadisticas

@admin_inscripcion_router.get("/reporte/clases-populares")
def generar_reporte_clases_populares(
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Generar reporte de clases más populares - Solo para administradores"""
    reporte = repositorio.obtener_clases_populares()
    return {
        "total_clases": len(reporte),
        "clases_populares": sorted(reporte, key=lambda x: x['total_inscripciones'], reverse=True)[:10]
    }

@admin_inscripcion_router.get("/reporte/clientes-activos")
def generar_reporte_clientes_activos(
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Generar reporte de clientes más activos - Solo para administradores"""
    reporte = repositorio.obtener_clientes_activos()
    return {
        "total_clientes": len(reporte),
        "clientes_activos": sorted(reporte, key=lambda x: x['total_inscripciones'], reverse=True)[:10]
    }

@admin_inscripcion_router.get("/reporte/temporal")
def generar_reporte_temporal(
    fecha_inicio: str = Query(..., description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: str = Query(..., description="Fecha fin (YYYY-MM-DD)"),
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Generar reporte de inscripciones por período - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d")
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    reporte = repositorio.generar_reporte_temporal(fecha_ini, fecha_fin_dt)
    
    return {
        "periodo": {
            "fecha_inicio": fecha_ini,
            "fecha_fin": fecha_fin_dt
        },
        "estadisticas": reporte
    }

@admin_inscripcion_router.get("/cliente/{cliente_dni}/completo")
def obtener_inscripciones_cliente_completo(
    cliente_dni: str,
    incluir_historicas: bool = Query(False, description="Incluir inscripciones históricas"),
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones),
    session: Session = Depends(get_session)
):
    """Obtener todas las inscripciones de un cliente (completo) - Solo para administradores"""
    cliente = session.exec(select(Cliente).where(Cliente.dni == cliente_dni)).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    if incluir_historicas:
        inscripciones = repositorio.listar_inscripciones_historicas_cliente(cliente_dni)
    else:
        inscripciones = repositorio.ver_inscripciones_cliente(cliente_dni)
    
    return {
        "cliente_dni": cliente_dni,
        "nombre_cliente": cliente.nombre,
        "total_inscripciones": len(inscripciones),
        "inscripciones": inscripciones
    }

@admin_inscripcion_router.get("/clase/{clase_id}/completo")
def obtener_inscripciones_clase_completo(
    clase_id: int,
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones),
    session: Session = Depends(get_session)
):
    """Obtener todas las inscripciones de una clase (completo) - Solo para administradores"""
    clase = session.get(Clase, clase_id)
    if not clase:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    
    inscripciones = repositorio.ver_inscripciones_clase_completas(clase_id)
    
    return {
        "clase_id": clase_id,
        "nombre_clase": clase.nombre,
        "instructor": clase.instructor,
        "total_inscripciones": len(inscripciones),
        "cupo_disponible": clase.cupo_maximo - len([i for i in inscripciones if i.estado == EstadoInscripcion.ACTIVO]),
        "inscripciones": inscripciones
    }

@admin_inscripcion_router.get("/alertas/cupos-criticos")
def obtener_alertas_cupos_criticos(
    porcentaje_alerta: int = Query(80, description="Porcentaje de ocupación para alerta"),
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Obtener alertas de clases con cupos críticos - Solo para administradores"""
    alertas = repositorio.obtener_clases_cupo_critico(porcentaje_alerta)
    
    return {
        "porcentaje_alerta": porcentaje_alerta,
        "total_alertas": len(alertas),
        "alertas": alertas
    }

@admin_inscripcion_router.get("/dashboard/estadisticas")
def obtener_dashboard_estadisticas(
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Obtener estadísticas para el dashboard administrativo - Solo para administradores"""
    estadisticas = repositorio.obtener_estadisticas_dashboard()
    
    return {
        "resumen": estadisticas,
        "ultimas_inscripciones": repositorio.obtener_ultimas_inscripciones(limit=10),
        "alertas_cupos": repositorio.obtener_clases_cupo_critico(90)
    }