# Casos_de_uso/modificar_contenido.py
from typing import Dict, Any
from sqlmodel import Session
from Adaptadores.adaptadorContenidoSQL import AdaptadorContenidoSQL
from models.contenido import Contenido

class ModificarContenidoCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_contenido = AdaptadorContenidoSQL(session)
    
    def ejecutar(self, contenido_id: int, datos_actualizacion: Dict[str, Any]) -> Contenido:
        contenido = self.repositorio_contenido.obtener_contenido_por_id(contenido_id)
        if not contenido:
            raise ValueError("Contenido no encontrado")
        
        # Validar longitud del título si se está actualizando
        if 'titulo' in datos_actualizacion and len(datos_actualizacion['titulo']) > 200:
            raise ValueError("El título no puede exceder los 200 caracteres")
        
        return self.repositorio_contenido.actualizar_contenido(contenido_id, datos_actualizacion)