# Casos_de_uso/crear_contenido.py
from typing import Dict, Any
from sqlmodel import Session
from Adaptadores.adaptadorContenidoSQL import AdaptadorContenidoSQL
from models.contenido import Contenido, ContenidoCreate

class CrearContenidoCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_contenido = AdaptadorContenidoSQL(session)
    
    def ejecutar(self, datos_contenido: Dict[str, Any]) -> Contenido:
        # Validaciones de negocio
        if not datos_contenido.get('titulo'):
            raise ValueError("El título del contenido es requerido")
        
        if not datos_contenido.get('categoria'):
            raise ValueError("La categoría del contenido es requerida")
        
        if len(datos_contenido.get('titulo', '')) > 200:
            raise ValueError("El título no puede exceder los 200 caracteres")
        
        contenido = Contenido(**datos_contenido)
        return self.repositorio_contenido.crear_contenido(contenido)