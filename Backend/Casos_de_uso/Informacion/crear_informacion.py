# Casos_de_uso/Informacion/crear_informacion.py
from sqlmodel import Session
from models.informacion import Informacion, InformacionCreate
from Adaptadores.adaptadorInformacionSQL import AdaptadorInformacionSQL

class CrearInformacionCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorInformacionSQL(session)
    
    def ejecutar(self, informacion_data: dict) -> Informacion:
        # Crear la información
        db_informacion = Informacion(**informacion_data)
        return self.repositorio.crear_informacion(db_informacion)

# Función existente para compatibilidad
def crear_informacion(informacion_data: InformacionCreate, repositorio) -> Informacion:
    db_informacion = Informacion(**informacion_data.dict())
    return repositorio.crear_informacion(db_informacion)