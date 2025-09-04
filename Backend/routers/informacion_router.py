from datetime import datetime
from fastapi import APIRouter, HTTPException, status, Depends
from sqlmodel import Session
from typing import List, Optional
from database import get_session
from models.informacion import Informacion, InformacionCreate, InformacionRead, InformacionStatsResponse, InformacionUpdate, TipoInformacion
from Dominio.repositorios.repositorioInformacion import RepositorioInformacion
from Adaptadores.adaptadorInformacionSQL import AdaptadorInformacionSQL

from Casos_de_uso.consultar_informacion import consultar_informacion

informacion_router = APIRouter(prefix="/api/informaciones", tags=["informaciones"])

# Dependency para obtener el repositorio de informaciones
def get_informacion_repository(session: Session = Depends(get_session)) -> RepositorioInformacion:
    return AdaptadorInformacionSQL(session)

@informacion_router.get("/", response_model=List[InformacionRead])
def list_informaciones(
    tipo: Optional[str] = None, 
    destinatario_id: Optional[int] = None, 
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener todas las informaciones, con filtros opcionales"""
    informaciones = consultar_informacion(repository, tipo=tipo, destinatario_id=destinatario_id)
    return informaciones

@informacion_router.get("/{informacion_id}", response_model=InformacionRead)
def get_informacion(
    informacion_id: int, 
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener una información específica por ID"""
    informacion = repository.obtener_informacion_por_id(informacion_id)
    if not informacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Información no encontrada")
    
    # Verificar si está expirada
    if informacion.fecha_expiracion and informacion.fecha_expiracion < datetime.utcnow():
        informacion.activa = False
    
    return informacion

@informacion_router.post("/", response_model=InformacionRead, status_code=status.HTTP_201_CREATED)
def create_informacion(
    informacion_data: InformacionCreate, 
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Crear una nueva información"""
    db_informacion = Informacion(**informacion_data.dict())
    
    try:
        return repository.crear_informacion(db_informacion)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Error al crear la información: {str(e)}")

@informacion_router.put("/{informacion_id}", response_model=InformacionRead)
def update_informacion(
    informacion_id: int,
    informacion_data: InformacionUpdate,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Actualizar una información existente"""
    datos_actualizados = informacion_data.dict(exclude_unset=True)
    
    try:
        informacion_actualizada = repository.actualizar_informacion(informacion_id, datos_actualizados)
        if not informacion_actualizada:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Información no encontrada")
        return informacion_actualizada
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Error al actualizar la información: {str(e)}")

@informacion_router.patch("/{informacion_id}/activar", response_model=InformacionRead)
def activar_informacion(
    informacion_id: int,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Reactivar una información"""
    informacion_activada = repository.activar_informacion(informacion_id)
    if not informacion_activada:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Información no encontrada")
    return informacion_activada

@informacion_router.patch("/{informacion_id}/desactivar", response_model=InformacionRead)
def desactivar_informacion(
    informacion_id: int,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Desactivar una información"""
    informacion_desactivada = repository.desactivar_informacion(informacion_id)
    if not informacion_desactivada:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Información no encontrada")
    return informacion_desactivada

@informacion_router.get("/cliente/{cliente_dni}", response_model=List[InformacionRead])
def get_informaciones_cliente(
    cliente_dni: str,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener informaciones para un cliente específico"""
    try:
        return repository.listar_informaciones_por_cliente(cliente_dni)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Error al obtener informaciones del cliente: {str(e)}")

@informacion_router.get("/tipo/{tipo}", response_model=List[InformacionRead])
def get_informaciones_por_tipo(
    tipo: TipoInformacion,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener informaciones por tipo"""
    return repository.listar_informaciones_por_tipo(tipo, activas=True)

@informacion_router.get("/estadisticas/totales", response_model=InformacionStatsResponse)
def get_estadisticas_informaciones(
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener estadísticas de todas las informaciones"""
    return repository.obtener_estadisticas()

@informacion_router.delete("/{informacion_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_informacion(
    informacion_id: int,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Eliminar permanentemente una información"""
    eliminada = repository.eliminar_informacion(informacion_id)
    if not eliminada:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Información no encontrada")

@informacion_router.get("/alertas/activas", response_model=List[InformacionRead])
def get_alertas_activas(
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Obtener todas las alertas activas"""
    return repository.listar_alertas_activas()

@informacion_router.get("/buscar/{palabra_clave}", response_model=List[InformacionRead])
def buscar_informaciones(
    palabra_clave: str,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Buscar informaciones por palabra clave"""
    return repository.buscar_informaciones_por_palabra(palabra_clave, activas=True)

@informacion_router.get("/fecha/{fecha}", response_model=List[InformacionRead])
def buscar_informaciones_por_fecha(
    fecha: datetime,
    repository: RepositorioInformacion = Depends(get_informacion_repository)
):
    """Buscar informaciones por fecha"""
    return repository.buscar_informaciones_por_fecha(fecha, activas=True)
