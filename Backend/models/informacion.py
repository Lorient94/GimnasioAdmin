from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from enum import Enum

class TipoInformacion(str, Enum):
    PERMANENTE = "permanente"
    ALERTA = "alerta"
    NOTICIA = "noticia"
    PROMOCION = "promocion"
    TODAS = "todas"
    ANUNCIO = "anuncio"
    EVENTO = "evento"
    RECORDATORIO = "recordatorio"   
    

class Informacion(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    titulo: str = Field(index=True)
    contenido: str
    tipo: TipoInformacion = Field(default=TipoInformacion.PERMANENTE, index=True)
    fecha_publicacion: datetime = Field(default_factory=datetime.utcnow)
    fecha_expiracion: Optional[datetime] = None
    activa: bool = Field(default=True)
    destinatario_id: Optional[int] = Field(default=None, foreign_key="cliente.id", index=True)
    prioridad: int = Field(default=1, ge=1, le=5)  # 1-5, donde 5 es máxima prioridad

# Modelos Pydantic para request/response
class InformacionBase(BaseModel):
    titulo: str
    contenido: str
    tipo: TipoInformacion
    fecha_expiracion: Optional[datetime] = None
    prioridad: Optional[int] = 1
    destinatario_id: Optional[int] = None

class InformacionCreate(InformacionBase):
    pass

class InformacionRead(InformacionBase):
    id: int
    fecha_publicacion: datetime
    activa: bool
    
    class Config:
        from_attributes = True

class InformacionUpdate(BaseModel):
    titulo: Optional[str] = None
    contenido: Optional[str] = None
    tipo: Optional[TipoInformacion] = None
    fecha_expiracion: Optional[datetime] = None
    activa: Optional[bool] = None
    prioridad: Optional[int] = None
    destinatario_id: Optional[int] = None

class InformacionStatsResponse(BaseModel):
    total: int
    activas: int
    permanentes: int
    alertas: int
    noticias: int
    promociones: int