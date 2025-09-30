# Casos_de_uso/Inscripciones/modificar_inscripcion_admin.py
from sqlmodel import Session
from models.inscripcion import Inscripcion
from Adaptadores.adaptadorInscripcionSQL import AdaptadorInscripcionesSQL

class ModificarInscripcionAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorInscripcionesSQL(session)
    
    def ejecutar(self, inscripcion_id: int, datos_actualizados: dict) -> Inscripcion:
        inscripcion = self.repositorio.consultar_inscripcion(inscripcion_id)
        if not inscripcion:
            raise ValueError("Inscripción no encontrada")
        
        return self.repositorio.actualizar_inscripcion(inscripcion_id, datos_actualizados)