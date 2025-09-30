# Casos_de_uso/Informacion/modificar_informacion.py
from sqlmodel import Session
from models.informacion import Informacion
from Adaptadores.adaptadorInformacionSQL import AdaptadorInformacionSQL

class ModificarInformacionCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorInformacionSQL(session)
    
    def ejecutar(self, informacion_id: int, datos_actualizados: dict) -> Informacion:
        # Verificar que la información existe
        informacion = self.repositorio.obtener_informacion_por_id(informacion_id)
        if not informacion:
            raise ValueError("Información no encontrada")
        
        return self.repositorio.actualizar_informacion(informacion_id, datos_actualizados)