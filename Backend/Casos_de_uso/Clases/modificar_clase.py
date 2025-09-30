# Casos_de_uso/modificar_clase.py
from typing import Any, Dict
from sqlmodel import Session
from Adaptadores.adaptadorClaseSQL import AdaptadorClaseSQL
from models.clase import Clase


class ModificarClaseCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_clases = AdaptadorClaseSQL(session)
    
    def ejecutar(self, clase_id: int, datos_actualizacion: Dict[str, Any]) -> Clase:
        clase = self.repositorio_clases.consultar_clase(clase_id)
        if not clase:
            raise ValueError("Clase no encontrada")
        
        # Validar que no se modifiquen clases con inscripciones activas
        if datos_actualizacion.get('cupo_maximo'):
            inscripciones_activas = self.repositorio_clases.obtener_inscripciones_activas(clase_id)
            if datos_actualizacion['cupo_maximo'] < len(inscripciones_activas):
                raise ValueError("El nuevo cupo no puede ser menor a las inscripciones activas")
        
        return self.repositorio_clases.actualizar_clase(clase_id, datos_actualizacion)