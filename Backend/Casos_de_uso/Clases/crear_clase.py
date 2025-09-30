# Casos_de_uso/crear_clase.py
from typing import Dict, Any
from sqlmodel import Session
from Adaptadores.adaptadorClaseSQL import AdaptadorClaseSQL
from models.clase import Clase, ClaseCreate

class CrearClaseCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_clases = AdaptadorClaseSQL(session)
    
    def ejecutar(self, datos_clase: Dict[str, Any]) -> Clase:
        # Validaciones de negocio
        if not datos_clase.get('nombre'):
            raise ValueError("El nombre de la clase es requerido")
        
        if datos_clase.get('cupo_maximo', 0) <= 0:
            raise ValueError("El cupo máximo debe ser mayor a 0")
        
        clase = Clase(**datos_clase)
        return self.repositorio_clases.crear_clase(clase)