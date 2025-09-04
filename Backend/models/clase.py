from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

# Entidad SQLModel
class Clase(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    nombre: str = Field(index=True)
    descripcion: Optional[str] = None
    activa: bool = Field(default=True)
    fecha_creacion: datetime = Field(default_factory=datetime.now)
    cupo_maximo: Optional[int] = Field(default=20, ge=1)
    instructor: Optional[str] = None
    duracion_minutos: Optional[int] = Field(default=60, ge=15)
    dificultad: Optional[str] = Field(default="Media")  # Baja, Media, Alta
    horario: Optional[str] = Field(default=None, description="Fecha y hora de la clase en formato 'YYYY-MM-DD HH:MM'")  # NUEVO ATRIBUTO
    
    # Relación con inscripciones
    inscripciones: List["Inscripcion"] = Relationship(back_populates="clase")

# Modelos Pydantic para request/response
class ClaseBase(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    cupo_maximo: Optional[int] = 20
    instructor: Optional[str] = None
    duracion_minutos: Optional[int] = 60
    dificultad: Optional[str] = "Media"
    horario: Optional[str] = None  # NUEVO ATRIBUTO

class ClaseCreate(ClaseBase):
    pass

class ClaseRead(ClaseBase):
    id: int
    activa: bool
    fecha_creacion: datetime
    
    class Config:
        from_attributes = True

class ClaseUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    activa: Optional[bool] = None
    cupo_maximo: Optional[int] = None
    instructor: Optional[str] = None
    duracion_minutos: Optional[int] = None
    dificultad: Optional[str] = None
    horario: Optional[str] = None  # NUEVO ATRIBUTO

class ClaseInscripcionResponse(BaseModel):
    mensaje: str
    clase_id: int
    cupos_disponibles: int