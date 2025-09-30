# Casos_de_uso/eliminar_contenido.py
from sqlmodel import Session
from Adaptadores.adaptadorContenidoSQL import AdaptadorContenidoSQL

class EliminarContenidoCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_contenido = AdaptadorContenidoSQL(session)
    
    def ejecutar(self, contenido_id: int) -> bool:
        contenido = self.repositorio_contenido.obtener_contenido_por_id(contenido_id)
        if not contenido:
            raise ValueError("Contenido no encontrado")
        
        # No hay validaciones adicionales para eliminar contenido
        return self.repositorio_contenido.eliminar_contenido(contenido_id)