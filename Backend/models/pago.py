# models/pago.py (corregido)
from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, TYPE_CHECKING
from datetime import datetime
from enum import Enum
from pydantic import BaseModel

if TYPE_CHECKING:
    from .transaccion import Transaccion
    from .cliente import Cliente

class EstadoPago(str, Enum):
    PENDIENTE = "pendiente"
    COMPLETADO = "completado"
    RECHAZADO = "rechazado"
    CANCELADO = "cancelado"
    REEMBOLSADO = "reembolsado"

class Pago(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    id_usuario: str = Field(foreign_key="cliente.dni", index=True)
    estado_pago: EstadoPago = Field(default=EstadoPago.PENDIENTE, index=True)
    transaccion_id: Optional[int] = Field(default=None, foreign_key="transaccion.id", index=True)
    fecha_creacion: datetime = Field(default_factory=datetime.utcnow)
    fecha_actualizacion: datetime = Field(default_factory=datetime.utcnow)
    monto: float = Field(ge=0.0)  # Quitar Optional, debe ser requerido
    concepto: str  # Quitar Optional
    referencia: Optional[str] = Field(default=None, unique=True, index=True)
    metodo_pago: str  # Quitar Optional
    observaciones: Optional[str] = None
    # nota: no incluir `mercado_pago_id` en el modelo de tabla si la columna
    # no existe en la base de datos. Si se desea persistir este campo,
    # agregar la columna en la BD o crear una migración.

    # Relaciones (usando string para evitar import circular)
    transaccion: Optional["Transaccion"] = Relationship(back_populates="pagos")
    cliente: Optional["Cliente"] = Relationship(back_populates="pagos")

# Modelos Pydantic para request/response
class PagoBase(BaseModel):
    id_usuario: str
    transaccion_id: Optional[int] = None
    monto: Optional[float] = None
    concepto: Optional[str] = None
    metodo_pago: Optional[str] = None
    observaciones: Optional[str] = None

class PagoCreate(PagoBase):
    pass

class PagoRead(PagoBase):
    id: int
    estado_pago: EstadoPago
    fecha_creacion: datetime
    fecha_actualizacion: datetime
    referencia: Optional[str] = None
    
    class Config:
        from_attributes = True

class PagoUpdate(BaseModel):
    estado_pago: Optional[EstadoPago] = None
    monto: Optional[float] = None
    concepto: Optional[str] = None
    metodo_pago: Optional[str] = None
    observaciones: Optional[str] = None

class PagoEstadoUpdate(BaseModel):
    estado_pago: EstadoPago
    observaciones: Optional[str] = None

class PagoStatsResponse(BaseModel):
    total: int
    pendientes: int
    completados: int
    rechazados: int
    monto_total: float
    monto_pendiente: float
    monto_completado: float