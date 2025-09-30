# Casos_de_uso/Inscripciones/crear_inscripcion_admin.py
from sqlmodel import Session, select
from models.inscripcion import Inscripcion
from models.cliente import Cliente
from models.clase import Clase
from Adaptadores.adaptadorInscripcionSQL import AdaptadorInscripcionesSQL

class CrearInscripcionAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorInscripcionesSQL(session)
    
    def ejecutar(self, inscripcion_data: dict) -> Inscripcion:
        # Validaciones básicas
        cliente = self.session.exec(select(Cliente).where(Cliente.dni == inscripcion_data['cliente_dni'])).first()
        if not cliente:
            raise ValueError("Cliente no encontrado")
        
        clase = self.session.get(Clase, inscripcion_data['clase_id'])
        if not clase:
            raise ValueError("Clase no encontrada")
        
        # Crear la inscripción
        db_inscripcion = Inscripcion(**inscripcion_data)
        return self.repositorio.crear_inscripcion(db_inscripcion)