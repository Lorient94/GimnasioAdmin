from fastapi import APIRouter, HTTPException, status, Depends, Query
from sqlmodel import Session, select
from typing import List, Optional
from datetime import datetime

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
from Casos_de_uso.inscribirse_a_clase import inscribirse_a_clase
from Casos_de_uso.cancelar_inscripcion import cancelar_inscripcion
from Casos_de_uso.ver_cronograma import ver_cronograma

inscripcion_router = APIRouter(prefix="/api/inscripciones", tags=["inscripciones"])

def get_repositorio_inscripciones(session: Session = Depends(get_session)) -> RepositorioInscripciones:
    """Dependency injection para el repositorio de inscripciones"""
    return AdaptadorInscripcionesSQL(session)

@inscripcion_router.get("", response_model=List[InscripcionRead])
def list_inscripciones(
    estado: Optional[EstadoInscripcion] = Query(None),
    cliente_dni: Optional[str] = Query(None),
    clase_id: Optional[int] = Query(None),
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones),
    session: Session = Depends(get_session)
):
    """Obtener todas las inscripciones, con filtros opcionales"""
    print(f"DEBUG ROUTER: Parámetros recibidos - cliente_dni={cliente_dni}, estado={estado}, clase_id={clase_id}")
    
    # Si se proporciona cliente_dni, verificar que el cliente existe
    if cliente_dni:
        # CORRECTO: Usar query where en lugar de session.get()
        cliente = session.exec(select(Cliente).where(Cliente.dni == cliente_dni)).first()
        if not cliente:
            print(f"DEBUG ROUTER: Cliente {cliente_dni} no encontrado en la base de datos")
            return []
        print(f"DEBUG ROUTER: Cliente {cliente_dni} encontrado: {cliente.nombre}")
    
    inscripciones = repositorio.listar_inscripciones(estado, cliente_dni, clase_id)
    print(f"DEBUG ROUTER: Encontradas {len(inscripciones)} inscripciones")
    
    return inscripciones

@inscripcion_router.get("/{inscripcion_id}", response_model=InscripcionRead)
def get_inscripcion(
    inscripcion_id: int, 
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Obtener una inscripción específica por ID"""
    inscripcion = repositorio.consultar_inscripcion(inscripcion_id)
    if not inscripcion:
        raise HTTPException(status_code=404, detail="Inscripción no encontrada")
    return inscripcion

@inscripcion_router.post("/", response_model=InscripcionRead, status_code=status.HTTP_201_CREATED)
def create_inscripcion(
    inscripcion_data: InscripcionCreate, 
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones),
    session: Session = Depends(get_session)
):
    """Crear una nueva inscripción usando el caso de uso"""
    print(f"DEBUG: Creando inscripción con datos: {inscripcion_data}")
    print(f"DEBUG: Tipo de datos: {type(inscripcion_data)}")
    
    # CORREGIDO: Buscar por DNI usando where
    cliente = session.exec(select(Cliente).where(Cliente.dni == inscripcion_data.cliente_dni)).first()
    if not cliente:
        print(f"DEBUG: Cliente {inscripcion_data.cliente_dni} no encontrado")
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    print(f"DEBUG: Cliente encontrado: {cliente.nombre}")
    
    # Verificar que la clase existe
    clase = session.get(Clase, inscripcion_data.clase_id)
    if not clase:
        print(f"DEBUG: Clase {inscripcion_data.clase_id} no encontrada")
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    print(f"DEBUG: Clase encontrada: {clase.nombre}")
    
    # Verificar si ya existe una inscripción activa para este cliente en esta clase
    existing_inscripciones = repositorio.listar_inscripciones(
        estado=EstadoInscripcion.ACTIVO,
        cliente_dni=inscripcion_data.cliente_dni,
        clase_id=inscripcion_data.clase_id
    )
    if existing_inscripciones:
        print(f"DEBUG: Ya existe inscripción activa para este cliente en esta clase")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El cliente ya está inscrito en esta clase"
        )
    
    try:
        print(f"DEBUG: Llamando a inscribirse_a_clase con: {inscripcion_data.dict()}")
        inscripcion_creada = inscribirse_a_clase(inscripcion_data.dict(), repositorio)
        print(f"DEBUG: Inscripción creada exitosamente: {inscripcion_creada.id}")
        return inscripcion_creada
    except ValueError as e:
        print(f"DEBUG: Error ValueError en inscribirse_a_clase: {str(e)}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        print(f"DEBUG: Error Exception en inscribirse_a_clase: {str(e)}")
        import traceback
        traceback.print_exc()  # Esto mostrará el traceback completo en los logs
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error interno: {str(e)}")


@inscripcion_router.put("/{inscripcion_id}", response_model=InscripcionRead)
def update_inscripcion(
    inscripcion_id: int,
    inscripcion_data: InscripcionUpdate,
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Actualizar una inscripción existente"""
    update_data = inscripcion_data.dict(exclude_unset=True)
    inscripcion_actualizada = repositorio.actualizar_inscripcion(inscripcion_id, update_data)
    if not inscripcion_actualizada:
        raise HTTPException(status_code=404, detail="Inscripción no encontrada")
    return inscripcion_actualizada

@inscripcion_router.patch("/{inscripcion_id}/cancelar", response_model=InscripcionRead)
def cancelar_inscripcion_endpoint(
    inscripcion_id: int,
    cancelacion_data: InscripcionCancelacion,
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Cancelar una inscripción usando el caso de uso"""
    inscripcion = repositorio.consultar_inscripcion(inscripcion_id)
    if not inscripcion:
        raise HTTPException(status_code=404, detail="Inscripción no encontrada")
    if inscripcion.estado == EstadoInscripcion.CANCELADO:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La inscripción ya está cancelada"
        )
    try:
        resultado = cancelar_inscripcion(inscripcion_id, cancelacion_data.motivo, repositorio)
        inscripcion_actualizada = repositorio.consultar_inscripcion(inscripcion_id)
        return inscripcion_actualizada
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))

@inscripcion_router.patch("/{inscripcion_id}/completar", response_model=InscripcionRead)
def completar_inscripcion(
    inscripcion_id: int, 
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Marcar una inscripción como completada"""
    inscripcion = repositorio.consultar_inscripcion(inscripcion_id)
    if not inscripcion:
        raise HTTPException(status_code=404, detail="Inscripción no encontrada")
    if not repositorio.completar_inscripcion(inscripcion_id):
        raise HTTPException(status_code=500, detail="Error al completar la inscripción")
    inscripcion_actualizada = repositorio.consultar_inscripcion(inscripcion_id)
    return inscripcion_actualizada

@inscripcion_router.get("/cliente/{cliente_dni}", response_model=List[InscripcionRead])
def get_inscripciones_cliente(
    cliente_dni: str, 
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones),
    session: Session = Depends(get_session)
):
    """Obtener todas las inscripciones de un cliente usando el caso de uso"""
    print(f"DEBUG: Buscando inscripciones para cliente (endpoint específico): {cliente_dni}")

    cliente = session.get(Cliente, cliente_dni)
    if not cliente:
        print(f"DEBUG: Cliente {cliente_dni} no encontrado")
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    inscripciones = ver_cronograma(cliente_dni, repositorio)
    print(f"DEBUG: Encontradas {len(inscripciones)} inscripciones")

    return inscripciones

@inscripcion_router.get("/clase/{clase_id}", response_model=List[InscripcionRead])
def get_inscripciones_clase(
    clase_id: int, 
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones),
    session: Session = Depends(get_session)
):
    """Obtener todas las inscripciones de una clase"""
    clase = session.get(Clase, clase_id)
    if not clase:
        raise HTTPException(status_code=404, detail="Clase no encontrada")
    inscripciones = repositorio.ver_inscripciones_clase(clase_id)
    return inscripciones

@inscripcion_router.get("/estadisticas/totales", response_model=InscripcionStatsResponse)
def get_estadisticas_inscripciones(
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Obtener estadísticas de todas las inscripciones"""
    estadisticas = repositorio.obtener_estadisticas()
    return InscripcionStatsResponse(
        total_inscripciones=estadisticas["total_inscripciones"],
        activas=estadisticas["activas"],
        canceladas=estadisticas["canceladas"],
        completadas=estadisticas["completadas"],
        pendientes=estadisticas["pendientes"]
    )

@inscripcion_router.delete("/{inscripcion_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_inscripcion(
    inscripcion_id: int, 
    repositorio: RepositorioInscripciones = Depends(get_repositorio_inscripciones)
):
    """Eliminar permanentemente una inscripción"""
    if not repositorio.eliminar_inscripcion(inscripcion_id):
        raise HTTPException(status_code=404, detail="Inscripción no encontrada")