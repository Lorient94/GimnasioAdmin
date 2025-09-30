# Casos_de_uso/Informacion/eliminar_informacion.py
from sqlmodel import Session
from Adaptadores.adaptadorInformacionSQL import AdaptadorInformacionSQL

class EliminarInformacionCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorInformacionSQL(session)
    
    def ejecutar(self, informacion_id: int) -> bool:
        # Verificar que la información existe
        informacion = self.repositorio.obtener_informacion_por_id(informacion_id)
        if not informacion:
            raise ValueError("Información no encontrada")
        
        return self.repositorio.eliminar_informacion(informacion_id)