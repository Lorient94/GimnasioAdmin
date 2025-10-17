# routers/admin/admin_inscripcion_router.py
from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlmodel import Session, select
from typing import List, Optional, Dict
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


# ========================
# DEPENDENCIAS Y UTILIDADES
# ========================
def get_repositorio_inscripciones(session: Session = Depends(get_session)) -> RepositorioInscripciones:
    return AdaptadorInscripcionesSQL(session)


def _parse_estado_inscripcion(valor: str) -> EstadoInscripcion:
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


# ========================
# ENDPOINTS CRUD
# ========================

@admin_inscripcion_router.get("/", response_model=List[InscripcionRead])
def listar_todas_las_inscripciones(
    estado: Optional[str] = Query(None),
    cliente_dni: Optional[str] = Query(None),
    clase_id: Optional[int] = Query(None),
    solo_activas: bool = Query(False, description="Filtrar solo inscripciones activas"),
    fecha_inicio: Optional[str] = Query(None, description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: Optional[str] = Query(None, description="Fecha fin (YYYY-MM-DD)"),
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    inscripciones = repositorio.listar_todas_las_inscripciones()
    
    # Filtros opcionales
    if estado:
        try:
            estado_enum = _parse_estado_inscripcion(estado)
            inscripciones = [ins for ins in inscripciones if ins.estado == estado_enum]
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

    if cliente_dni:
        inscripciones = [ins for ins in inscripciones if ins.cliente_dni == cliente_dni]

    if clase_id:
        inscripciones = [ins for ins in inscripciones if ins.clase_id == clase_id]

    if solo_activas:
        inscripciones = [ins for ins in inscripciones if ins.estado == EstadoInscripcion.ACTIVO]

    # Filtrar por fecha
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


@admin_inscripcion_router.post("/", response_model=InscripcionRead, status_code=status.HTTP_201_CREATED)
def crear_inscripcion_admin(inscripcion_data: InscripcionCreate, session: Session = Depends(get_session)):
    caso_uso = CrearInscripcionAdminCase(session)
    try:
        inscripcion_creada = caso_uso.ejecutar(inscripcion_data.dict())
        return inscripcion_creada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear la inscripción: {str(e)}")


# ========================
# REPORTES Y ESTADÍSTICAS
# ========================

@admin_inscripcion_router.get("/reporte/clases-populares")
def generar_reporte_clases_populares(
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Generar reporte de clases más populares"""
    reporte = repositorio.obtener_clases_populares() or []

    # Asegurar formato consistente
    for item in reporte:
        if "total_inscripciones" not in item and "inscripciones" in item:
            item["total_inscripciones"] = item["inscripciones"]

    return {
        "total_clases": len(reporte),
        "clases_populares": sorted(
            reporte, 
            key=lambda x: x.get("total_inscripciones", 0), 
            reverse=True
        )[:10]
    }
from typing import List, Dict
from fastapi import APIRouter, Query, Depends
from sqlmodel import Session, select
from models.clase import Clase
from database import get_session

from typing import List, Dict

@admin_inscripcion_router.get("/alertas/cupos-criticos", response_model=Dict[str, List[Dict]])
def obtener_alertas_cupos_criticos(
    porcentaje_alerta: int = Query(80, ge=1, le=100, description="Porcentaje a partir del cual alertar"),
    session: Session = Depends(get_session),
):
    """
    Devuelve un diccionario con la lista de clases cuyo cupo esté por encima del porcentaje indicado.
    Ejemplo porcentaje_alerta=80 => clases con más del 80% del cupo ocupado.
    """
    clases_query = session.exec(select(Clase)).all()
    alertas = []

    for clase in clases_query:
        if clase.cupo_maximo and clase.inscripciones:
            try:
                cupo_max = int(clase.cupo_maximo)
                ocupadas = len([i for i in clase.inscripciones if i.estado == "activo"])
                porcentaje_ocupacion = (ocupadas / cupo_max) * 100

                if porcentaje_ocupacion >= porcentaje_alerta:
                    alertas.append({
                        "nombre": clase.nombre,
                        "instructor": getattr(clase, "instructor", None),
                        "cupo_maximo": cupo_max,
                        "ocupadas": ocupadas,
                        "porcentaje_ocupacion": round(porcentaje_ocupacion, 2),
                    })
            except (ValueError, TypeError):
                # Ignorar clases con cupo_maximo no válido
                pass

    return {"alertas": alertas}  # ✅ clave explícita

@admin_inscripcion_router.get("/reporte/clientes-activos")
def generar_reporte_clientes_activos(
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Generar reporte de clientes más activos"""
    reporte = repositorio.obtener_clientes_activos() or []

    for item in reporte:
        if "total_inscripciones" not in item and "inscripciones" in item:
            item["total_inscripciones"] = item["inscripciones"]

    return {
        "total_clientes": len(reporte),
        "clientes_activos": sorted(
            reporte, 
            key=lambda x: x.get("total_inscripciones", 0),
            reverse=True
        )[:10]
    }


@admin_inscripcion_router.get("/reporte/temporal")
def generar_reporte_temporal(
    fecha_inicio: str = Query(..., description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: str = Query(..., description="Fecha fin (YYYY-MM-DD)"),
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Generar reporte de inscripciones por período"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d")
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")

    reporte = repositorio.generar_reporte_temporal(fecha_ini, fecha_fin_dt) or {}

    return {
        "periodo": {
            "fecha_inicio": fecha_ini.strftime("%Y-%m-%d"),
            "fecha_fin": fecha_fin_dt.strftime("%Y-%m-%d")
        },
        "estadisticas": reporte
    }
