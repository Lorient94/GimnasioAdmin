from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import datetime
from pydantic import BaseModel

# Entidad SQLModel
class Contenido(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    categoria: str = Field(index=True)  # video, foto, texto, enlace
    titulo: str = Field(index=True)
    descripcion: Optional[str] = None
    url: Optional[str] = None
    activo: bool = Field(default=True)
    fecha_creacion: datetime = Field(default_factory=datetime.utcnow)
    fecha_actualizacion: datetime = Field(default_factory=datetime.utcnow)

# Modelos Pydantic para request/response
class ContenidoBase(BaseModel):
    categoria: str
    titulo: str
    descripcion: Optional[str] = None
    url: Optional[str] = None

class ContenidoCreate(ContenidoBase):
    pass

class ContenidoRead(ContenidoBase):
    id: int
    activo: bool
    fecha_creacion: datetime
    fecha_actualizacion: datetime
    
    class Config:
        from_attributes = True

class ContenidoUpdate(BaseModel):
    categoria: Optional[str] = None
    titulo: Optional[str] = None
    descripcion: Optional[str] = None
    url: Optional[str] = None
    activo: Optional[bool] = None

class ContenidoCategoriaResponse(BaseModel):
    categoria: str
    cantidad: int
    contenidos: list[ContenidoRead]