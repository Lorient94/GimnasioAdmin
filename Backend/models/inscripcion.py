from enum import Enum
from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

class EstadoInscripcion(str, Enum):
    ACTIVO = "activo"
    CANCELADO = "cancelado"
    PENDIENTE = "pendiente"
    COMPLETADO = "completado"

# Entidad SQLModel (mantener igual)
class Inscripcion(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    cliente_dni: str = Field(foreign_key="cliente.dni", index=True)
    clase_id: int = Field(foreign_key="clase.id", index=True)
    fecha_inscripcion: datetime = Field(default_factory=datetime.utcnow)
    estado: EstadoInscripcion = Field(default=EstadoInscripcion.ACTIVO)
    pagado: bool = Field(default=False)
    transaccion_id: Optional[int] = Field(default=None, foreign_key="transaccion.id")
    fecha_cancelacion: Optional[datetime] = None
    motivo_cancelacion: Optional[str] = None

    # Relaciones
    cliente: Optional["Cliente"] = Relationship(back_populates="inscripciones")
    clase: Optional["Clase"] = Relationship(back_populates="inscripciones")
    transaccion: Optional["Transaccion"] = Relationship(back_populates="inscripciones")

# Modelos Pydantic para request/response
class InscripcionBase(BaseModel):
    cliente_dni: str
    clase_id: int
    estado: Optional[EstadoInscripcion] = EstadoInscripcion.ACTIVO
    pagado: Optional[bool] = False

class InscripcionCreate(InscripcionBase):
    cliente_dni: str
    clase_id: int
    fecha_inscripcion: datetime
    estado: EstadoInscripcion = Field(default=EstadoInscripcion.ACTIVO)
    pagado: bool = Field(default=False)
    
# MODELO ACTUALIZADO - Agregar campos relacionados
class InscripcionRead(InscripcionBase):
    id: int
    fecha_inscripcion: datetime
    fecha_cancelacion: Optional[datetime] = None
    motivo_cancelacion: Optional[str] = None
    transaccion_id: Optional[int] = None
    
    # CAMPOS NUEVOS para datos relacionados
    nombre_cliente: Optional[str] = None
    email_cliente: Optional[str] = None
    clase_nombre: Optional[str] = None
    clase_instructor: Optional[str] = None
    clase_precio: Optional[float] = None
    
    class Config:
        from_attributes = True

class InscripcionUpdate(BaseModel):
    estado: Optional[EstadoInscripcion] = None
    pagado: Optional[bool] = None
    motivo_cancelacion: Optional[str] = None

class InscripcionCancelacion(BaseModel):
    motivo: str = Field(..., min_length=1, max_length=500)

class InscripcionStatsResponse(BaseModel):
    total_inscripciones: int
    activas: int
    canceladas: int
    completadas: int
    pendientes: int