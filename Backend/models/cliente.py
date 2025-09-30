from sqlmodel import Relationship, SQLModel, Field, Session, select
from typing import List, Optional, Dict, Any, TYPE_CHECKING
from datetime import date
from pydantic import BaseModel

# Entidad SQLModel
class Cliente(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    dni: str = Field(index=True, unique=True)
    nombre: str
    fecha_nacimiento: date
    telefono: str
    correo: str = Field(index=True, unique=True)
    ciudad: Optional[str] = None
    genero: Optional[str] = None
    password: str
    activo: bool = Field(default=True)
    fecha_registro: date = Field(default_factory=date.today)

    transacciones: List["Transaccion"] = Relationship(back_populates="cliente")
    inscripciones: List["Inscripcion"] = Relationship(back_populates="cliente")
    pagos: List["Pago"] = Relationship(back_populates="cliente")  # 👈 esta línea faltaba

# Modelos Pydantic para request/response
class ClienteBase(BaseModel):
    dni: str
    nombre: str
    fecha_nacimiento: date
    telefono: str
    correo: str

class ClienteCreate(ClienteBase):
    genero: Optional[str] = None
    ciudad: Optional[str] = None

class ClienteRead(ClienteBase):
    id: int
    direccion: Optional[str] = None
    genero: Optional[str] = None
    activo: bool
    
    class Config:
        from_attributes = True

class ClienteUpdate(BaseModel):
    nombre: Optional[str] = None
    telefono: Optional[str] = None
    correo: Optional[str] = None
    genero: Optional[str] = None
    ciudad: Optional[str] = None
    activo: Optional[bool] = None
    password: Optional[str] = None

class LoginRequest(BaseModel):
    correo: str
    password: str

class VerificacionResponse(BaseModel):
    existe: bool


class ClienteStatsResponse(BaseModel):
    total_clientes: int
    clientes_activos: int
    clientes_inactivos: int
    porcentaje_activos: float
    nuevos_ultima_semana: Optional[int] = 0
    membresias_expiracion_proxima: Optional[int] = 0


if TYPE_CHECKING:
    # Importaciones solo para el chequeo de tipos y linters (evitan importaciones circulares en runtime)
    from models.transaccion import Transaccion  # noqa: F401
    from models.inscripcion import Inscripcion  # noqa: F401
    from models.pago import Pago  # noqa: F401