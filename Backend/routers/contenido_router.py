from fastapi import APIRouter, HTTPException, Response, status, Depends
from sqlmodel import Session
from typing import List, Optional
from datetime import datetime

from database import get_session
from models.contenido import Contenido, ContenidoCreate, ContenidoRead, ContenidoUpdate, ContenidoCategoriaResponse
from Dominio.repositorios.repositorioContenido import RepositorioContenido
from Adaptadores.adaptadorContenidoSQL import AdaptadorContenidoSQL

contenido_router = APIRouter(prefix="/api/contenidos", tags=["contenidos"])

# Dependency para obtener el repositorio de contenidos
def get_contenido_repository(session: Session = Depends(get_session)) -> RepositorioContenido:
    return AdaptadorContenidoSQL(session)

@contenido_router.get("/", response_model=List[ContenidoRead])
def list_contenidos(
    activos: bool = True,
    categoria: Optional[str] = None,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener todos los contenidos, con filtros opcionales"""
    contenidos = repository.listar_contenidos(activos=activos, categoria=categoria)
    return contenidos

@contenido_router.get("/{contenido_id}", response_model=ContenidoRead)
def get_contenido(
    contenido_id: int, 
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener un contenido específico por ID"""
    contenido = repository.obtener_contenido_por_id(contenido_id)
    if not contenido:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    return contenido

@contenido_router.post("/", response_model=ContenidoRead, status_code=status.HTTP_201_CREATED)
def create_contenido(
    contenido_data: ContenidoCreate, 
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Crear un nuevo contenido"""
    db_contenido = Contenido(**contenido_data.dict())
    
    try:
        contenido_creado = repository.crear_contenido(db_contenido)
        return contenido_creado
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al crear el contenido: {str(e)}"
        )

@contenido_router.put("/{contenido_id}", response_model=ContenidoRead)
def update_contenido(
    contenido_id: int,
    contenido_data: ContenidoUpdate,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Actualizar un contenido existente"""
    datos_actualizados = contenido_data.dict(exclude_unset=True)
    contenido_actualizado = repository.actualizar_contenido(contenido_id, datos_actualizados)
    
    if not contenido_actualizado:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    
    return contenido_actualizado

@contenido_router.delete("/{contenido_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contenido(
    contenido_id: int,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Eliminar un contenido (soft delete)"""
    eliminado = repository.eliminar_contenido(contenido_id)
    if not eliminado:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")

@contenido_router.get("/categoria/{categoria_name}", response_model=List[ContenidoRead])
def get_contenidos_by_categoria(
    categoria_name: str,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener todos los contenidos de una categoría específica"""
    contenidos = repository.listar_contenidos_por_categoria(categoria_name, activos=True)
    return contenidos

@contenido_router.get("/categorias/todas", response_model=List[ContenidoCategoriaResponse])
def get_contenidos_por_categoria(
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener contenidos agrupados por categoría"""
    return repository.listar_contenidos_agrupados_por_categoria()

@contenido_router.patch("/{contenido_id}/activar", response_model=ContenidoRead)
def activar_contenido(
    contenido_id: int,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Reactivar un contenido previamente desactivado"""
    contenido_activado = repository.activar_contenido(contenido_id)
    if not contenido_activado:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    return contenido_activado

@contenido_router.get("/buscar/{palabra_clave}", response_model=List[ContenidoRead])
def buscar_contenidos(
    palabra_clave: str,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Buscar contenidos por palabra clave en título o descripción"""
    contenidos = repository.buscar_contenidos(palabra_clave, activos=True)
    return contenidos

@contenido_router.get("/fecha/{fecha_str}", response_model=List[ContenidoRead])
def buscar_contenidos_por_fecha(
    fecha_str: str,  # ← Ahora acepta string directamente
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Buscar contenidos por fecha específica (formato: YYYY-MM-DD)"""
    contenidos = repository.buscar_contenidos_por_fecha(fecha_str, activos=True)
    return contenidos

@contenido_router.get("/{contenido_id}/descargar")
def descargar_contenido(
    contenido_id: int,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Descargar el contenido (si tiene URL)"""
    contenido_bytes = repository.descargar_contenido(contenido_id)
    if not contenido_bytes:
        raise HTTPException(status_code=404, detail="Contenido no disponible para descarga")
    
    # Obtener información del contenido para el nombre del archivo
    contenido = repository.obtener_contenido_por_id(contenido_id)
    filename = f"{contenido.titulo.replace(' ', '_')}.bin" if contenido else "contenido.bin"
    
    return Response(
        content=contenido_bytes,
        media_type="application/octet-stream",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )