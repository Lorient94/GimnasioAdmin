# routers/admin_informacion_router.py
from datetime import datetime
from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlmodel import Session
from typing import List, Optional

from database import get_session
from models.informacion import Informacion, InformacionCreate, InformacionRead, InformacionStatsResponse, InformacionUpdate, TipoInformacion
from Dominio.repositorios.repositorioInformacion import RepositorioInformacion
from Adaptadores.adaptadorInformacionSQL import AdaptadorInformacionSQL

# Importar casos de uso
from Casos_de_uso.Informacion.crear_informacion import CrearInformacionCase
from Casos_de_uso.Informacion.modificar_informacion import ModificarInformacionCase
from Casos_de_uso.Informacion.eliminar_informacion import EliminarInformacionCase

admin_informacion_router = APIRouter(prefix="/api/admin/informaciones", tags=["admin-informaciones"])

def get_informacion_repository(session: Session = Depends(get_session)) -> RepositorioInformacion:
    return AdaptadorInformacionSQL(session)

@admin_informacion_router.get("/", response_model=List[InformacionRead])
def listar_todas_las_informaciones(
    solo_activas: bool = Query(False, description="Filtrar solo informaciones activas"),
    tipo: Optional[TipoInformacion] = Query(None, description="Filtrar por tipo"),
    destinatario_id: Optional[int] = Query(None, description="Filtrar por destinatario"),
    incluir_expiradas: bool = Query(False, description="Incluir informaciones expiradas"),
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener todas las informaciones (incluyendo inactivas) - Solo para administradores"""
    informaciones = repository.listar_todas_las_informaciones()
    
    # Aplicar filtros
    if solo_activas:
        informaciones = [info for info in informaciones if info.activa]
    
    if tipo:
        informaciones = [info for info in informaciones if info.tipo == tipo]
    
    if destinatario_id:
        informaciones = [info for info in informaciones if info.destinatario_id == destinatario_id]
    
    if not incluir_expiradas:
        ahora = datetime.utcnow()
        informaciones = [info for info in informaciones if 
                        not info.fecha_expiracion or info.fecha_expiracion > ahora]
    
    return informaciones

@admin_informacion_router.get("/{informacion_id}", response_model=InformacionRead)
def obtener_informacion_detallada(
    informacion_id: int, 
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener una información con todos los detalles - Solo para administradores"""
    informacion = repository.obtener_informacion_por_id(informacion_id)
    if not informacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Información no encontrada")
    
    return informacion

@admin_informacion_router.post("/", response_model=InformacionRead, status_code=status.HTTP_201_CREATED)
def crear_informacion_admin(
    informacion_data: InformacionCreate, 
    session: Session = Depends(get_session)
):
    """Crear una nueva información - Solo para administradores"""
    caso_uso = CrearInformacionCase(session)
    
    try:
        informacion_creada = caso_uso.ejecutar(informacion_data.dict())
        return informacion_creada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear la información: {str(e)}")


@admin_informacion_router.put("/{informacion_id}", response_model=InformacionRead)
def actualizar_informacion_admin(
    informacion_id: int,
    informacion_data: InformacionUpdate,
    session: Session = Depends(get_session)
):
    """Actualizar una información existente - Solo para administradores"""
    caso_uso = ModificarInformacionCase(session)
    
    try:
        datos_actualizacion = informacion_data.dict(exclude_unset=True)
        informacion_actualizada = caso_uso.ejecutar(informacion_id, datos_actualizacion)
        return informacion_actualizada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar la información: {str(e)}")

@admin_informacion_router.patch("/{informacion_id}/activar", response_model=InformacionRead)
def activar_informacion_admin(
    informacion_id: int,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Reactivar una información - Solo para administradores"""
    informacion_activada = repository.activar_informacion(informacion_id)
    if not informacion_activada:
        raise HTTPException(status_code=404, detail="Información no encontrada")
    return informacion_activada

@admin_informacion_router.patch("/{informacion_id}/desactivar", response_model=InformacionRead)
def desactivar_informacion_admin(
    informacion_id: int,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Desactivar una información - Solo para administradores"""
    informacion_desactivada = repository.desactivar_informacion(informacion_id)
    if not informacion_desactivada:
        raise HTTPException(status_code=404, detail="Información no encontrada")
    return informacion_desactivada

@admin_informacion_router.delete("/{informacion_id}", status_code=status.HTTP_200_OK)
def eliminar_informacion_admin(
    informacion_id: int,
    session: Session = Depends(get_session)
):
    """Eliminar permanentemente una información - Solo para administradores"""
    caso_uso = EliminarInformacionCase(session)
    
    try:
        eliminada = caso_uso.ejecutar(informacion_id)
        if eliminada:
            return {"message": "Información eliminada permanentemente"}
        else:
            raise HTTPException(status_code=404, detail="Información no encontrada")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar la información: {str(e)}")

@admin_informacion_router.delete("/batch/eliminar", status_code=status.HTTP_200_OK)
def eliminar_informaciones_masivas(
    informacion_ids: List[int] = Query(..., description="Lista de IDs a eliminar"),
    session: Session = Depends(get_session)
):
    """Eliminar múltiples informaciones de forma masiva - Solo para administradores"""
    caso_uso = EliminarInformacionCase(session)
    resultados = []
    
    for info_id in informacion_ids:
        try:
            eliminada = caso_uso.ejecutar(info_id)
            resultados.append({
                "id": info_id,
                "eliminada": eliminada,
                "mensaje": "Eliminada correctamente" if eliminada else "No encontrada"
            })
        except Exception as e:
            resultados.append({
                "id": info_id,
                "eliminada": False,
                "error": str(e)
            })
    
    return {
        "total_solicitadas": len(informacion_ids),
        "eliminadas_exitosas": len([r for r in resultados if r.get("eliminada")]),
        "detalles": resultados
    }

@admin_informacion_router.get("/estadisticas/avanzadas", response_model=InformacionStatsResponse)
def obtener_estadisticas_avanzadas(
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener estadísticas avanzadas de todas las informaciones - Solo para administradores"""
    estadisticas = repository.obtener_estadisticas_avanzadas()
    return estadisticas

@admin_informacion_router.get("/reporte/tipos")
def generar_reporte_por_tipo(
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Generar reporte detallado por tipo de información - Solo para administradores"""
    informaciones = repository.listar_todas_las_informaciones()
    
    reporte = {}
    for tipo in TipoInformacion:
        reporte[tipo.value] = {
            "total": 0,
            "activas": 0,
            "inactivas": 0,
            "expiradas": 0,
            "con_expiracion": 0,
            "sin_expiracion": 0,
            "promedio_dias_validez": 0,
            "ejemplos": []
        }
    
    ahora = datetime.utcnow()
    for info in informaciones:
        tipo_key = info.tipo.value
        reporte[tipo_key]["total"] += 1
        
        if info.activa:
            reporte[tipo_key]["activas"] += 1
        else:
            reporte[tipo_key]["inactivas"] += 1
        
        if info.fecha_expiracion:
            reporte[tipo_key]["con_expiracion"] += 1
            if info.fecha_expiracion < ahora:
                reporte[tipo_key]["expiradas"] += 1
        else:
            reporte[tipo_key]["sin_expiracion"] += 1
        
        # Agregar ejemplo (máximo 3 por tipo)
        if len(reporte[tipo_key]["ejemplos"]) < 3:
            reporte[tipo_key]["ejemplos"].append({
                "id": info.id,
                "titulo": info.titulo,
                "fecha_creacion": info.fecha_creacion,
                "activa": info.activa
            })
    
    # Calcular promedios
    for tipo in reporte:
        if reporte[tipo]["con_expiracion"] > 0:
            # Esto sería mejor calcularlo con consultas específicas a la base de datos
            reporte[tipo]["promedio_dias_validez"] = 30  # Placeholder
    
    return reporte

@admin_informacion_router.get("/reporte/temporal")
def generar_reporte_temporal(
    fecha_inicio: str = Query(..., description="Fecha inicio (YYYY-MM-DD)"),
    fecha_fin: str = Query(..., description="Fecha fin (YYYY-MM-DD)"),
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Generar reporte de informaciones por período temporal - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d")
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    informaciones = repository.listar_informaciones_por_rango_fechas(fecha_ini, fecha_fin_dt)
    
    reporte = {
        "periodo": {
            "fecha_inicio": fecha_ini,
            "fecha_fin": fecha_fin_dt
        },
        "totales": {
            "informaciones_creadas": len(informaciones),
            "por_tipo": {},
            "activas": 0,
            "inactivas": 0
        },
        "detalles": []
    }
    
    for info in informaciones:
        # Estadísticas por tipo
        tipo = info.tipo.value
        if tipo not in reporte["totales"]["por_tipo"]:
            reporte["totales"]["por_tipo"][tipo] = 0
        reporte["totales"]["por_tipo"][tipo] += 1
        
        # Contar activas/inactivas
        if info.activa:
            reporte["totales"]["activas"] += 1
        else:
            reporte["totales"]["inactivas"] += 1
        
        # Detalles
        reporte["detalles"].append({
            "id": info.id,
            "titulo": info.titulo,
            "tipo": info.tipo.value,
            "fecha_creacion": info.fecha_creacion,
            "activa": info.activa,
            "destinatario_id": info.destinatario_id
        })
    
    return reporte

@admin_informacion_router.get("/alertas/expiracion-proxima")
def obtener_alertas_expiracion_proxima(
    dias_antes: int = Query(7, description="Días antes de la expiración para alertar"),
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener informaciones que expirarán pronto - Solo para administradores"""
    alertas = repository.obtener_informaciones_por_expiracion_proxima(dias_antes)
    
    return {
        "dias_antes_alerta": dias_antes,
        "total_alertas": len(alertas),
        "alertas": alertas
    }

@admin_informacion_router.get("/buscar/avanzada")
def busqueda_avanzada_informaciones(
    palabra_clave: Optional[str] = Query(None),
    tipo: Optional[TipoInformacion] = Query(None),
    destinatario_id: Optional[int] = Query(None),
    activa: Optional[bool] = Query(None),
    fecha_inicio: Optional[str] = Query(None),
    fecha_fin: Optional[str] = Query(None),
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Búsqueda avanzada de informaciones - Solo para administradores"""
    try:
        fecha_ini = datetime.strptime(fecha_inicio, "%Y-%m-%d") if fecha_inicio else None
        fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d") if fecha_fin else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")
    
    resultados = repository.busqueda_avanzada(
        palabra_clave=palabra_clave,
        tipo=tipo,
        destinatario_id=destinatario_id,
        activa=activa,
        fecha_inicio=fecha_ini,
        fecha_fin=fecha_fin_dt
    )
    
    return {
        "parametros_busqueda": {
            "palabra_clave": palabra_clave,
            "tipo": tipo.value if tipo else None,
            "destinatario_id": destinatario_id,
            "activa": activa,
            "fecha_inicio": fecha_inicio,
            "fecha_fin": fecha_fin
        },
        "total_resultados": len(resultados),
        "resultados": resultados
    }

@admin_informacion_router.patch("/batch/activar")
def activar_informaciones_masivas(
    informacion_ids: List[int] = Query(..., description="Lista de IDs a activar"),
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Activar múltiples informaciones de forma masiva - Solo para administradores"""
    resultados = []
    
    for info_id in informacion_ids:
        try:
            informacion_activada = repository.activar_informacion(info_id)
            resultados.append({
                "id": info_id,
                "activada": informacion_activada is not None,
                "mensaje": "Activada correctamente" if informacion_activada else "No encontrada"
            })
        except Exception as e:
            resultados.append({
                "id": info_id,
                "activada": False,
                "error": str(e)
            })
    
    return {
        "total_solicitadas": len(informacion_ids),
        "activadas_exitosas": len([r for r in resultados if r.get("activada")]),
        "detalles": resultados
    }

@admin_informacion_router.patch("/batch/desactivar")
def desactivar_informaciones_masivas(
    informacion_ids: List[int] = Query(..., description="Lista de IDs a desactivar"),
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Desactivar múltiples informaciones de forma masiva - Solo para administradores"""
    resultados = []
    
    for info_id in informacion_ids:
        try:
            informacion_desactivada = repository.desactivar_informacion(info_id)
            resultados.append({
                "id": info_id,
                "desactivada": informacion_desactivada is not None,
                "mensaje": "Desactivada correctamente" if informacion_desactivada else "No encontrada"
            })
        except Exception as e:
            resultados.append({
                "id": info_id,
                "desactivada": False,
                "error": str(e)
            })
    
    return {
        "total_solicitadas": len(informacion_ids),
        "desactivadas_exitosas": len([r for r in resultados if r.get("desactivada")]),
        "detalles": resultados
    }

@admin_informacion_router.get("/cliente/{cliente_dni}/completo")
def obtener_informaciones_cliente_completo(
    cliente_dni: str,
    incluir_inactivas: bool = Query(False, description="Incluir informaciones inactivas"),
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener todas las informaciones de un cliente (completo) - Solo para administradores"""
    try:
        informaciones = repository.listar_informaciones_por_cliente(cliente_dni)
        
        if not incluir_inactivas:
            informaciones = [info for info in informaciones if info.activa]
        
        return {
            "cliente_dni": cliente_dni,
            "total_informaciones": len(informaciones),
            "informaciones": informaciones
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener informaciones del cliente: {str(e)}")

@admin_informacion_router.get("/dashboard/estadisticas")
def obtener_dashboard_estadisticas(
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener estadísticas para el dashboard administrativo - Solo para administradores"""
    estadisticas = repository.obtener_estadisticas_dashboard()
    
    return {
        "resumen": estadisticas,
        "ultimas_actividades": repository.obtener_ultimas_informaciones_creadas(limit=10),
        "alertas_expiracion": repository.obtener_informaciones_por_expiracion_proxima(3)
    }