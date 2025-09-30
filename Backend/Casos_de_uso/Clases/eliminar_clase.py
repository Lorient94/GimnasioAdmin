# Casos_de_uso/eliminar_clase.py
from sqlmodel import Session
from Adaptadores.adaptadorClaseSQL import AdaptadorClaseSQL


class EliminarClaseCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_clases = AdaptadorClaseSQL(session)
    
    def ejecutar(self, clase_id: int) -> bool:
        clase = self.repositorio_clases.consultar_clase(clase_id)
        if not clase:
            raise ValueError("Clase no encontrada")
        
        # Validar que no tenga inscripciones activas
        inscripciones_activas = self.repositorio_clases.obtener_inscripciones_activas(clase_id)
        if inscripciones_activas:
            raise ValueError("No se puede eliminar una clase con inscripciones activas")
        
        return self.repositorio_clases.eliminar_clase(clase_id)