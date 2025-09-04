from fastapi import APIRouter, HTTPException, status, Depends
from sqlmodel import Session
from typing import List, Optional
from datetime import datetime, timedelta
import uuid

from database import get_session
from models.transaccion import (
    Transaccion, TransaccionCreate, TransaccionRead, TransaccionUpdate,
    TransaccionEstadoUpdate, TransaccionStatsResponse, MetodoPagoStats,
    EstadoPago, MetodoPago
)
from models.cliente import Cliente
from Adaptadores.adaptadorTransaccionSQL import AdaptadorTransaccionSQL
from Dominio.repositorios.repositorioTransaccion import RepositorioTransaccion

transaccion_router = APIRouter(prefix="/api/transacciones", tags=["transacciones"])

def get_repositorio_transacciones(session: Session = Depends(get_session)) -> RepositorioTransaccion:
    """Dependency injection para el repositorio de transacciones"""
    return AdaptadorTransaccionSQL(session)

@transaccion_router.get("/", response_model=List[TransaccionRead])
def list_transacciones(
    estado: Optional[EstadoPago] = None,
    cliente_dni: Optional[str] = None,
    metodo_pago: Optional[MetodoPago] = None,
    fecha_inicio: Optional[datetime] = None,
    fecha_fin: Optional[datetime] = None,
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener todas las transacciones, con filtros opcionales"""
    transacciones = repositorio.listar_transacciones(
        estado=estado,
        cliente_dni=cliente_dni,
        metodo_pago=metodo_pago,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin
    )
    return transacciones

@transaccion_router.get("/{transaccion_id}", response_model=TransaccionRead)
def get_transaccion(
    transaccion_id: int, 
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener una transacción específica por ID"""
    transaccion = repositorio.consultar_transaccion(transaccion_id)
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    return transaccion

@transaccion_router.get("/referencia/{referencia}", response_model=TransaccionRead)
def get_transaccion_por_referencia(
    referencia: str, 
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener una transacción por referencia"""
    transaccion = repositorio.consultar_transaccion_por_referencia(referencia)
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    return transaccion

@transaccion_router.post("/", response_model=TransaccionRead, status_code=status.HTTP_201_CREATED)
def create_transaccion(
    transaccion_data: TransaccionCreate, 
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones),
    session: Session = Depends(get_session)
):
    """Crear una nueva transacción"""
    # Verificar que el cliente existe
    cliente = session.get(Cliente, transaccion_data.cliente_dni)
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    # Generar referencia única si no se proporciona
    if not transaccion_data.referencia:
        transaccion_data.referencia = f"TRX-{uuid.uuid4().hex[:8].upper()}"
    
    # Verificar si la referencia ya existe
    if transaccion_data.referencia:
        existing_ref = repositorio.consultar_transaccion_por_referencia(transaccion_data.referencia)
        if existing_ref:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ya existe una transacción con esta referencia"
            )
    
    db_transaccion = Transaccion(**transaccion_data.dict())
    transaccion_creada = repositorio.crear_transaccion(db_transaccion)
    return transaccion_creada

@transaccion_router.put("/{transaccion_id}", response_model=TransaccionRead)
def update_transaccion(
    transaccion_id: int,
    transaccion_data: TransaccionUpdate,
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Actualizar una transacción existente"""
    update_data = transaccion_data.dict(exclude_unset=True)
    transaccion_actualizada = repositorio.actualizar_transaccion(transaccion_id, update_data)
    
    if not transaccion_actualizada:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    return transaccion_actualizada

@transaccion_router.patch("/{transaccion_id}/estado", response_model=TransaccionRead)
def cambiar_estado_transaccion(
    transaccion_id: int,
    estado_data: TransaccionEstadoUpdate,
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Cambiar el estado de una transacción"""
    # Primero verificamos si la transacción existe
    transaccion = repositorio.consultar_transaccion(transaccion_id)
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    # Cambiamos el estado
    if not repositorio.cambiar_estado_transaccion(
        transaccion_id, 
        estado_data.estado, 
        estado_data.observaciones
    ):
        raise HTTPException(status_code=500, detail="Error al cambiar el estado de la transacción")
    
    # Obtenemos la transacción actualizada
    transaccion_actualizada = repositorio.consultar_transaccion(transaccion_id)
    return transaccion_actualizada

@transaccion_router.get("/cliente/{cliente_dni}", response_model=List[TransaccionRead])
def get_transacciones_cliente(
    cliente_dni: str, 
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones),
    session: Session = Depends(get_session)
):
    """Obtener todas las transacciones de un cliente"""
    # Verificar que el cliente existe
    cliente = session.get(Cliente, cliente_dni)
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    transacciones = repositorio.ver_historial_transacciones(cliente_dni)
    return transacciones

@transaccion_router.get("/estadisticas/totales", response_model=TransaccionStatsResponse)
def get_estadisticas_transacciones(
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener estadísticas de todas las transacciones"""
    estadisticas = repositorio.obtener_estadisticas_totales()
    
    return TransaccionStatsResponse(
        total=estadisticas["total"],
        pendientes=estadisticas["pendientes"],
        completadas=estadisticas["completadas"],
        rechazadas=estadisticas["rechazadas"],
        monto_total=estadisticas["monto_total"],
        monto_pendiente=estadisticas["monto_pendiente"],
        monto_completado=estadisticas["monto_completado"]
    )

@transaccion_router.get("/estadisticas/metodos-pago", response_model=List[MetodoPagoStats])
def get_estadisticas_metodos_pago(
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Obtener estadísticas por método de pago"""
    estadisticas = repositorio.obtener_estadisticas_metodos_pago()
    
    resultado = []
    for stats in estadisticas:
        resultado.append(MetodoPagoStats(
            metodo=stats["metodo"],
            cantidad=stats["cantidad"],
            monto_total=stats["monto_total"]
        ))
    
    return resultado

@transaccion_router.get("/ultimo-mes/{cliente_dni}", response_model=List[TransaccionRead])
def get_transacciones_ultimo_mes(
    cliente_dni: str, 
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones),
    session: Session = Depends(get_session)
):
    """Obtener transacciones del último mes de un cliente"""
    # Verificar que el cliente existe
    cliente = session.get(Cliente, cliente_dni)
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    transacciones = repositorio.ver_transacciones_ultimo_mes(cliente_dni)
    return transacciones

@transaccion_router.delete("/{transaccion_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaccion(
    transaccion_id: int, 
    repositorio: RepositorioTransaccion = Depends(get_repositorio_transacciones)
):
    """Eliminar permanentemente una transacción"""
    if not repositorio.eliminar_transaccion(transaccion_id):
        raise HTTPException(status_code=404, detail="Transacción no encontrada")