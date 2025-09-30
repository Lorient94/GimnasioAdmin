# Casos_de_uso/Inscripciones/eliminar_inscripcion_admin.py
from sqlmodel import Session
from Adaptadores.adaptadorInscripcionSQL import AdaptadorInscripcionesSQL

class EliminarInscripcionAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorInscripcionesSQL(session)
    
    def ejecutar(self, inscripcion_id: int) -> bool:
        inscripcion = self.repositorio.consultar_inscripcion(inscripcion_id)
        if not inscripcion:
            raise ValueError("Inscripción no encontrada")
        
        return self.repositorio.eliminar_inscripcion_permanentemente(inscripcion_id)