from fastapi import APIRouter, HTTPException, status, Depends
from sqlmodel import Session
from typing import List, Optional
from models.clase import Clase, ClaseCreate, ClaseRead, ClaseUpdate
from Dominio.repositorios.repositorioClase import RepositorioClase 
from Adaptadores.adaptadorClaseSQL import AdaptadorClaseSQL
from database import get_session

from Casos_de_uso.consultar_clases import consultar_clases

clase_router = APIRouter(prefix="/api/clases", tags=["clases"])

def get_clase_repository(session: Session = Depends(get_session)) -> RepositorioClase:
    return AdaptadorClaseSQL(session)

@clase_router.get("/", response_model=List[ClaseRead])
def list_clases(
    activas: bool = True, 
    instructor: Optional[str] = None, 
    horario: Optional[str] = None, 
    repository: RepositorioClase = Depends(get_clase_repository)
):
    clases = consultar_clases(repository, activas=activas, instructor=instructor, horario=horario)
    return clases


@clase_router.get("/{clase_id}", response_model=ClaseRead)
def get_clase(
    clase_id: int, 
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Obtener una clase específica por ID"""
    clase = repository.obtener_clase_por_id(clase_id)
    if not clase:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    return clase

@clase_router.post("/", response_model=ClaseRead, status_code=status.HTTP_201_CREATED)
def create_clase(
    clase_data: ClaseCreate, 
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Crear una nueva clase"""
    # Verificar si ya existe una clase con el mismo nombre
    if repository.verificar_nombre_existente(clase_data.nombre):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una clase con este nombre"
        )
    
    # Crear entidad Clase
    db_clase = Clase(**clase_data.dict())
    
    try:
        clase_creada = repository.crear_clase(db_clase)
        return clase_creada
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al crear la clase: {str(e)}"
        )

@clase_router.put("/{clase_id}", response_model=ClaseRead)
def update_clase(
    clase_id: int,
    clase_data: ClaseUpdate,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Actualizar una clase existente"""
    # Verificar si el nombre ya existe (excluyendo la clase actual)
    if clase_data.nombre:
        if repository.verificar_nombre_existente(clase_data.nombre, excluir_id=clase_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe una clase con este nombre"
            )
    
    # Actualizar la clase
    datos_actualizados = clase_data.dict(exclude_unset=True)
    clase_actualizada = repository.actualizar_clase(clase_id, datos_actualizados)
    
    if not clase_actualizada:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    
    return clase_actualizada

@clase_router.delete("/{clase_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_clase(
    clase_id: int,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Eliminar una clase (soft delete)"""
    eliminada = repository.eliminar_clase(clase_id)
    if not eliminada:
        raise HTTPException(status_code=404, detail="Clase no encontrada")

@clase_router.get("/instructor/{instructor_name}", response_model=List[ClaseRead])
def get_clases_by_instructor(
    instructor_name: str,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Obtener todas las clases de un instructor específico"""
    clases = repository.listar_clases_por_instructor(instructor_name)
    return clases

@clase_router.get("/dificultad/{nivel}", response_model=List[ClaseRead])
def get_clases_by_dificultad(
    nivel: str,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Obtener clases por nivel de dificultad"""
    niveles_validos = ["Baja", "Media", "Alta"]
    if nivel not in niveles_validos:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Nivel de dificultad debe ser: {', '.join(niveles_validos)}"
        )
    
    clases = repository.listar_clases_por_dificultad(nivel, activas=True)
    return clases

@clase_router.get("/horario/{horario}", response_model=List[ClaseRead])
def get_clases_by_horario(
    horario: str,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Obtener clases por horario específico"""
    clases = repository.listar_clases_por_horario(horario, activas=True)
    return clases

@clase_router.patch("/{clase_id}/activar", response_model=ClaseRead)
def activar_clase(
    clase_id: int,
    repository: RepositorioClase = Depends(get_clase_repository)
):
    """Reactivar una clase previamente desactivada"""
    clase_activada = repository.activar_clase(clase_id)
    if not clase_activada:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    return clase_activada