# models/transaccion.py - VERSIÓN CORREGIDA
from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List, TYPE_CHECKING
from datetime import datetime
from enum import Enum
from pydantic import BaseModel

if TYPE_CHECKING:
    from .cliente import Cliente
    from .pago import Pago
    from .inscripcion import Inscripcion

class MetodoPago(str, Enum):
    TRANSFERENCIA = "transferencia"
    TARJETA_CREDITO = "tarjeta de crédito"
    TARJETA_DEBITO = "tarjeta de débito"
    BILLETERA_VIRTUAL = "billetera virtual"
    EFECTIVO = "efectivo"
    MERCADO_PAGO = "mercado_pago"  # ✅ AGREGAR ESTE

class EstadoTransaccion(str, Enum):  # ✅ CAMBIAR DE EstadoPago a EstadoTransaccion
    PENDIENTE = "pendiente"
    COMPLETADA = "completada"  # ✅ CAMBIAR DE "completado" a "completada"
    RECHAZADA = "rechazada"    # ✅ CAMBIAR DE "rechazado" a "rechazada"
    CANCELADA = "cancelada"    # ✅ CAMBIAR DE "cancelado" a "cancelada"
    REEMBOLSADA = "reembolsada" # ✅ CAMBIAR DE "reembolsado" a "reembolsada"

# Entidad SQLModel
class Transaccion(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    cliente_dni: str = Field(foreign_key="cliente.dni", index=True)
    monto: float = Field(ge=0.0)
    fecha: datetime = Field(default_factory=datetime.utcnow, index=True)
    metodo_pago: MetodoPago = Field(index=True)
    estado: EstadoTransaccion = Field(default=EstadoTransaccion.PENDIENTE, index=True)  # ✅ CAMBIAR AQUÍ
    url_comprobante: Optional[str] = None
    concepto: Optional[str] = None
    descuento: Optional[float] = Field(default=0.0, ge=0.0)
    observaciones: Optional[str] = None
    fecha_actualizacion: datetime = Field(default_factory=datetime.utcnow)
    referencia: Optional[str] = Field(default=None, unique=True, index=True)

    # Relaciones
    cliente: Optional["Cliente"] = Relationship(back_populates="transacciones")
    pagos: List["Pago"] = Relationship(back_populates="transaccion")
    inscripciones: List["Inscripcion"] = Relationship(back_populates="transaccion")


# Modelos Pydantic para request/response
class TransaccionBase(BaseModel):
    cliente_dni: str
    monto: float
    metodo_pago: MetodoPago
    concepto: Optional[str] = None
    descuento: Optional[float] = 0.0
    observaciones: Optional[str] = None
    referencia: Optional[str] = None

class TransaccionCreate(TransaccionBase):
    pass

class TransaccionRead(TransaccionBase):
    id: int
    fecha: datetime
    estado: EstadoTransaccion  # ✅ CAMBIAR AQUÍ
    url_comprobante: Optional[str] = None
    fecha_actualizacion: datetime
    
    class Config:
        from_attributes = True

class TransaccionUpdate(BaseModel):
    estado: Optional[EstadoTransaccion] = None  # ✅ CAMBIAR AQUÍ
    url_comprobante: Optional[str] = None
    observaciones: Optional[str] = None
    descuento: Optional[float] = None

class TransaccionEstadoUpdate(BaseModel):
    estado: EstadoTransaccion  # ✅ CAMBIAR AQUÍ
    observaciones: Optional[str] = None

class TransaccionStatsResponse(BaseModel):
    total: int
    pendientes: int
    completadas: int
    rechazadas: int
    monto_total: float
    monto_pendiente: float
    monto_completado: float

class MetodoPagoStats(BaseModel):
    metodo: MetodoPago
    cantidad: int
    monto_total: float