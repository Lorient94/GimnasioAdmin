from fastapi import APIRouter, HTTPException, status, Depends
from sqlmodel import Session
from typing import List, Optional
from datetime import datetime
import uuid

from database import get_session
from models.pago import (
    Pago, PagoCreate, PagoRead, PagoUpdate, PagoEstadoUpdate,
    PagoStatsResponse, EstadoPago
)
from models.cliente import Cliente
from models.transaccion import Transaccion
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL
from Dominio.repositorios.repositorioPago import RepositorioPago

pago_router = APIRouter(prefix="/api/pago", tags=["pagos"])

def get_repositorio_pagos(session: Session = Depends(get_session)) -> RepositorioPago:
    """Dependency injection para el repositorio de pagos"""
    return AdaptadorPagoSQL(session)

@pago_router.get("/", response_model=List[PagoRead])
def list_pagos(
    estado_pago: Optional[EstadoPago] = None,
    id_usuario: Optional[str] = None,
    transaccion_id: Optional[int] = None,
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener todos los pagos, con filtros opcionales"""
    pagos = repositorio.listar_pagos(
        estado_pago=estado_pago,
        id_usuario=id_usuario,
        transaccion_id=transaccion_id
    )
    return pagos

@pago_router.get("/{pago_id}", response_model=PagoRead)
def get_pago(
    pago_id: int, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener un pago específico por ID"""
    pago = repositorio.consultar_pago(pago_id)
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    return pago

@pago_router.get("/usuario/{usuario_dni}", response_model=List[PagoRead])
def get_pagos_usuario(
    usuario_dni: str, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos),
    session: Session = Depends(get_session)
):
    """Obtener todos los pagos de un usuario"""
    # Verificar que el usuario existe
    usuario = session.get(Cliente, usuario_dni)
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    pagos = repositorio.obtener_pagos_usuario(usuario_dni)
    return pagos

@pago_router.get("/transaccion/{transaccion_id}", response_model=List[PagoRead])
def get_pagos_transaccion(
    transaccion_id: int, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos),
    session: Session = Depends(get_session)
):
    """Obtener todos los pagos de una transacción"""
    # Verificar que la transacción existe
    transaccion = session.get(Transaccion, transaccion_id)
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    pagos = repositorio.obtener_pagos_transaccion(transaccion_id)
    return pagos

@pago_router.post("/", response_model=PagoRead, status_code=status.HTTP_201_CREATED)
def create_pago(
    pago_data: PagoCreate, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos),
    session: Session = Depends(get_session)
):
    """Crear un nuevo pago"""
    # Verificar que el usuario existe
    usuario = session.get(Cliente, pago_data.id_usuario)
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # Si se proporciona transacción_id, verificar que existe
    if pago_data.transaccion_id:
        transaccion = session.get(Transaccion, pago_data.transaccion_id)
        if not transaccion:
            raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    # Generar referencia única
    referencia = f"PAGO-{uuid.uuid4().hex[:8].upper()}"
    
    db_pago = Pago(
        **pago_data.dict(),
        referencia=referencia
    )
    
    pago_creado = repositorio.crear_pago(db_pago)
    return pago_creado

@pago_router.put("/{pago_id}", response_model=PagoRead)
def update_pago(
    pago_id: int,
    pago_data: PagoUpdate,
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Actualizar un pago existente"""
    update_data = pago_data.dict(exclude_unset=True)
    pago_actualizado = repositorio.actualizar_pago(pago_id, update_data)
    
    if not pago_actualizado:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    
    return pago_actualizado

@pago_router.patch("/{pago_id}/estado", response_model=PagoRead)
def cambiar_estado_pago(
    pago_id: int,
    estado_data: PagoEstadoUpdate,
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Cambiar el estado de un pago"""
    # Primero verificamos si el pago existe
    pago = repositorio.consultar_pago(pago_id)
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    
    # Cambiamos el estado
    if not repositorio.cambiar_estado_pago(
        pago_id, 
        estado_data.estado_pago, 
        estado_data.observaciones
    ):
        raise HTTPException(status_code=500, detail="Error al cambiar el estado del pago")
    
    # Obtenemos el pago actualizado
    pago_actualizado = repositorio.consultar_pago(pago_id)
    return pago_actualizado

@pago_router.patch("/{pago_id}/completar", response_model=PagoRead)
def completar_pago(
    pago_id: int, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Marcar un pago como completado"""
    # Primero verificamos si el pago existe
    pago = repositorio.consultar_pago(pago_id)
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    
    # Completamos el pago
    if not repositorio.completar_pago(pago_id):
        raise HTTPException(status_code=500, detail="Error al completar el pago")
    
    # Obtenemos el pago actualizado
    pago_actualizado = repositorio.consultar_pago(pago_id)
    return pago_actualizado

@pago_router.patch("/{pago_id}/rechazar", response_model=PagoRead)
def rechazar_pago(
    pago_id: int, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Marcar un pago como rechazado"""
    # Primero verificamos si el pago existe
    pago = repositorio.consultar_pago(pago_id)
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    
    # Rechazamos el pago
    if not repositorio.rechazar_pago(pago_id):
        raise HTTPException(status_code=500, detail="Error al rechazar el pago")
    
    # Obtenemos el pago actualizado
    pago_actualizado = repositorio.consultar_pago(pago_id)
    return pago_actualizado

@pago_router.get("/estadisticas/totales", response_model=PagoStatsResponse)
def get_estadisticas_pagos(
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener estadísticas de todos los pagos"""
    estadisticas = repositorio.obtener_estadisticas_totales()
    
    return PagoStatsResponse(
        total=estadisticas["total"],
        pendientes=estadisticas["pendientes"],
        completados=estadisticas["completados"],
        rechazados=estadisticas["rechazados"],
        monto_total=estadisticas["monto_total"],
        monto_pendiente=estadisticas["monto_pendiente"],
        monto_completado=estadisticas["monto_completado"]
    )

@pago_router.get("/referencia/{referencia}", response_model=PagoRead)
def get_pago_por_referencia(
    referencia: str, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Obtener un pago por referencia"""
    pago = repositorio.consultar_pago_por_referencia(referencia)
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    return pago

@pago_router.delete("/{pago_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_pago(
    pago_id: int, 
    repositorio: RepositorioPago = Depends(get_repositorio_pagos)
):
    """Eliminar permanentemente un pago"""
    if not repositorio.eliminar_pago(pago_id):
        raise HTTPException(status_code=404, detail="Pago no encontrado")