from sqlmodel import Relationship, SQLModel, Field, Column, JSON
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel
from enum import Enum

# Enum para días de la semana
class DiaSemana(str, Enum):
    lunes = "lunes"
    martes = "martes"
    miercoles = "miercoles"
    jueves = "jueves"
    viernes = "viernes"
    sabado = "sabado"
    domingo = "domingo"

# Modelo de tabla Clase
class Clase(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    nombre: str = Field(index=True)
    descripcion: Optional[str] = None
    activa: bool = Field(default=True)
    fecha_creacion: datetime = Field(default_factory=datetime.now)
    cupo_maximo: Optional[int] = Field(default=20, ge=1)
    instructor: Optional[str] = None
    duracion_minutos: Optional[int] = Field(default=60, ge=15)
    dificultad: Optional[str] = Field(default="Media")
    
    # Nueva forma de manejar recurrencia
    dias_semana: List[DiaSemana] = Field(
        sa_column=Column(JSON),
        default_factory=list, 
        description="Días de la semana en los que se repite la clase")
    hora: Optional[str] = Field(default=None, description="Hora de la clase en formato 'HH:MM'")

    # Relación con inscripciones
    inscripciones: List["Inscripcion"] = Relationship(back_populates="clase")

    # Compatibilidad: alias/properties para mantener compatibilidad con
    # código existente que espera otros nombres de atributos.
    @property
    def nivel_dificultad(self) -> Optional[str]:
        """Alias: nivel_dificultad -> dificultad"""
        return self.dificultad

    @property
    def duracion(self) -> Optional[int]:
        """Alias: duracion -> duracion_minutos"""
        return self.duracion_minutos

    # Campos opcionales que pueden estar presentes en datos legacy; si no
    # existen en la tabla, devolvemos None para mantener compatibilidad.
    @property
    def requisitos(self) -> Optional[str]:
        return getattr(self, '_requisitos', None)

    @property
    def materiales_necesarios(self) -> Optional[str]:
        return getattr(self, '_materiales_necesarios', None)

# ---------------------------
# MODELOS PYDANTIC
# ---------------------------

class ClaseBase(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    cupo_maximo: Optional[int] = 20
    instructor: Optional[str] = None
    duracion_minutos: Optional[int] = 60
    dificultad: Optional[str] = "Media"
    dias_semana: Optional[List[DiaSemana]] = None
    hora: Optional[str] = None  # NUEVO ATRIBUTO

class ClaseCreate(ClaseBase):
    pass

class ClaseRead(ClaseBase):
    id: int
    nombre: str
    instructor: Optional[str]
    dificultad: Optional[str]
    hora: Optional[str]  
    dias_semana: List[str]
    activa: bool

    class Config:
        orm_mode = True

class ClaseUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    activa: Optional[bool] = None
    cupo_maximo: Optional[int] = None
    instructor: Optional[str] = None
    duracion_minutos: Optional[int] = None
    dificultad: Optional[str] = None
    dias_semana: Optional[List[DiaSemana]] = None
    hora: Optional[str] = None

class ClaseInscripcionResponse(BaseModel):
    mensaje: str
    clase_id: int
    cupos_disponibles: int
