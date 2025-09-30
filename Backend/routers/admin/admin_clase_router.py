# routers/admin_clase_router.py
from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlmodel import Session
from typing import List, Optional, Dict, Any
from datetime import datetime

from database import get_session
from models.clase import Clase, ClaseCreate, ClaseRead, ClaseUpdate
from Adaptadores.adaptadorClaseSQL import AdaptadorClaseSQL
from Dominio.repositorios.repositorioClase import RepositorioClase

# Importar casos de uso
from Casos_de_uso.Clases.crear_clase import CrearClaseCase
from Casos_de_uso.Clases.modificar_clase import ModificarClaseCase
from Casos_de_uso.Clases.eliminar_clase import EliminarClaseCase

admin_clase_router = APIRouter(prefix="/api/admin/clases", tags=["admin-clases"])

def get_clase_repository(session: Session = Depends(get_session)) -> RepositorioClase:
    return AdaptadorClaseSQL(session)

@admin_clase_router.get("/", response_model=List[ClaseRead])
def listar_todas_las_clases(
    solo_activas: bool = Query(False, description="Filtrar solo clases activas"),
    instructor: Optional[str] = Query(None, description="Filtrar por instructor"),
    dificultad: Optional[str] = Query(None, description="Filtrar por nivel de dificultad"),
    horario: Optional[str] = Query(None, description="Filtrar por horario"),
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Obtener todas las clases (incluyendo inactivas) - Solo para administradores"""
    if solo_activas:
        clases = repository.listar_clases(activas=True, instructor=instructor)
    else:
        clases = repository.listar_todas_las_clases(instructor=instructor)
    
    # Aplicar filtros adicionales
    if dificultad:
        niveles_validos = ["Baja", "Media", "Alta"]
        if dificultad not in niveles_validos:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Nivel de dificultad debe ser: {', '.join(niveles_validos)}"
            )
        clases = [clase for clase in clases if clase.nivel_dificultad == dificultad]
    
    if horario:
        clases = [clase for clase in clases if horario.lower() in clase.hora.lower()]
    
    return clases

@admin_clase_router.get("/{clase_id}", response_model=ClaseRead)
def obtener_clase_detallada(
    clase_id: int, 
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Obtener una clase con todos los detalles - Solo para administradores"""
    clase = repository.obtener_clase_por_id(clase_id)
    if not clase:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    return clase

@admin_clase_router.post("/", response_model=ClaseRead, status_code=status.HTTP_201_CREATED)
def crear_clase_admin(
    clase_data: ClaseCreate, 
    session: Session = Depends(get_session)
):
    """Crear una nueva clase - Solo para administradores"""
    caso_uso = CrearClaseCase(session)
    
    try:
        clase_creada = caso_uso.ejecutar(clase_data.dict())
        return clase_creada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear la clase: {str(e)}")

@admin_clase_router.put("/{clase_id}", response_model=ClaseRead)
def actualizar_clase_admin(
    clase_id: int,
    clase_data: ClaseUpdate,
    session: Session = Depends(get_session)
):
    """Actualizar una clase existente - Solo para administradores"""
    caso_uso = ModificarClaseCase(session)
    
    try:
        datos_actualizacion = clase_data.dict(exclude_unset=True)
        clase_actualizada = caso_uso.ejecutar(clase_id, datos_actualizacion)
        return clase_actualizada
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar la clase: {str(e)}")

@admin_clase_router.delete("/{clase_id}", status_code=status.HTTP_200_OK)
def desactivar_clase(
    clase_id: int,
    session: Session = Depends(get_session)
):
    """Desactivar una clase (soft delete) - Solo para administradores"""
    caso_uso = EliminarClaseCase(session)
    
    try:
        eliminada = caso_uso.ejecutar(clase_id)
        if eliminada:
            return {"message": "Clase desactivada correctamente"}
        else:
            raise HTTPException(status_code=404, detail="Clase no encontrada")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al desactivar la clase: {str(e)}")

@admin_clase_router.patch("/{clase_id}/activar", response_model=ClaseRead)
def activar_clase_admin(
    clase_id: int,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Reactivar una clase desactivada - Solo para administradores"""
    clase_activada = repository.activar_clase(clase_id)
    if not clase_activada:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    return clase_activada

@admin_clase_router.get("/{clase_id}/estadisticas")
def obtener_estadisticas_clase(
    clase_id: int,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Obtener estadísticas detalladas de una clase - Solo para administradores"""
    # Primero verificar que la clase existe
    clase = repository.obtener_clase_por_id(clase_id)
    if not clase:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    
    # Obtener estadísticas básicas
    estadisticas = repository.obtener_estadisticas_clase(clase_id)
    
    return {
        "clase_id": clase_id,
        "nombre": clase.nombre,
        "instructor": clase.instructor,
        "estadisticas": estadisticas
    }

@admin_clase_router.get("/{clase_id}/inscripciones")
def obtener_inscripciones_clase(
    clase_id: int,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Obtener todas las inscripciones de una clase - Solo para administradores"""
    # Verificar que la clase existe
    clase = repository.obtener_clase_por_id(clase_id)
    if not clase:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    
    inscripciones = repository.obtener_inscripciones_activas(clase_id)
    return {
        "clase_id": clase_id,
        "nombre_clase": clase.nombre,
        "total_inscripciones": len(inscripciones),
        "inscripciones": inscripciones
    }

@admin_clase_router.get("/reporte/ocupacion")
def generar_reporte_ocupacion(
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Generar reporte de ocupación de todas las clases - Solo para administradores"""
    clases = repository.listar_clases(activas=True)
    
    reporte = []
    for clase in clases:
        stats = repository.obtener_estadisticas_clase(clase.id)
        reporte.append({
            'clase_id': clase.id,
            'nombre': clase.nombre,
            'instructor': clase.instructor,
            'horario': clase.hora,
            'dias_semana': clase.dias_semana,
            'cupo_maximo': stats.get('cupo_maximo', 0),
            'inscripciones_activas': stats.get('inscripciones_activas', 0),
            'cupos_disponibles': stats.get('cupos_disponibles', 0),
            'porcentaje_ocupacion': round(stats.get('porcentaje_ocupacion', 0), 2)
        })
    
    return sorted(reporte, key=lambda x: x['porcentaje_ocupacion'], reverse=True)

@admin_clase_router.get("/reporte/dificultad")
def generar_reporte_por_dificultad(
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Generar reporte agrupado por nivel de dificultad - Solo para administradores"""
    clases = repository.listar_clases(activas=True)
    
    reporte = {
        "Baja": {"total_clases": 0, "total_inscritos": 0, "clases": []},
        "Media": {"total_clases": 0, "total_inscritos": 0, "clases": []},
        "Alta": {"total_clases": 0, "total_inscritos": 0, "clases": []}
    }
    
    for clase in clases:
        stats = repository.obtener_estadisticas_clase(clase.id)
        nivel = clase.nivel_dificultad
        
        if nivel in reporte:
            reporte[nivel]["total_clases"] += 1
            reporte[nivel]["total_inscritos"] += stats.get('inscripciones_activas', 0)
            reporte[nivel]["clases"].append({
                'id': clase.id,
                'nombre': clase.nombre,
                'instructor': clase.instructor,
                'inscritos': stats.get('inscripciones_activas', 0)
            })
    
    return reporte

@admin_clase_router.get("/reporte/instructores")
def generar_reporte_instructores(
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Generar reporte de clases por instructor - Solo para administradores"""
    clases = repository.listar_clases(activas=True)
    
    reporte = {}
    
    for clase in clases:
        instructor = clase.instructor
        stats = repository.obtener_estadisticas_clase(clase.id)
        
        if instructor not in reporte:
            reporte[instructor] = {
                "total_clases": 0,
                "total_inscritos": 0,
                "clases": []
            }
        
        reporte[instructor]["total_clases"] += 1
        reporte[instructor]["total_inscritos"] += stats.get('inscripciones_activas', 0)
        reporte[instructor]["clases"].append({
            'id': clase.id,
            'nombre': clase.nombre,
            'horario': clase.hora,
            'dificultad': clase.nivel_dificultad,
            'inscritos': stats.get('inscripciones_activas', 0)
        })
    
    return reporte

@admin_clase_router.post("/{clase_id}/duplicar", response_model=ClaseRead)
def duplicar_clase(
    clase_id: int,
    nuevo_nombre: str = Query(..., description="Nombre para la nueva clase duplicada"),
    session: Session = Depends(get_session)
):
    """Duplicar una clase existente - Solo para administradores"""
    repository = AdaptadorClaseSQL(session)
    
    # Obtener la clase original
    clase_original = repository.obtener_clase_por_id(clase_id)
    if not clase_original:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    
    # Verificar que el nuevo nombre no exista
    if repository.verificar_nombre_existente(nuevo_nombre):
        raise HTTPException(
            status_code=400,
            detail="Ya existe una clase con este nombre"
        )
    
    # Crear nueva clase basada en la original
    nueva_clase_data = {
        "nombre": nuevo_nombre,
        "descripcion": clase_original.descripcion,
        "instructor": clase_original.instructor,
        "hora": clase_original.hora,
        "duracion": clase_original.duracion,
        "dias_semana": clase_original.dias_semana,
        "nivel_dificultad": clase_original.nivel_dificultad,
        "cupo_maximo": clase_original.cupo_maximo,
        "requisitos": clase_original.requisitos,
        "materiales_necesarios": clase_original.materiales_necesarios
    }
    
    caso_uso = CrearClaseCase(session)
    
    try:
        clase_duplicada = caso_uso.ejecutar(nueva_clase_data)
        return clase_duplicada
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error al duplicar la clase: {str(e)}"
        )