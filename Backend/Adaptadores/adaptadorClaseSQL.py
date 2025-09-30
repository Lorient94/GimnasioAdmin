# Adaptadores/adaptadorClaseSQL.py - VERSIÓN COMPLETA
from Dominio.repositorios.repositorioClase import RepositorioClase
from models.clase import Clase
from sqlmodel import Session, select
from typing import List, Optional, Dict, Any

class AdaptadorClaseSQL(RepositorioClase):
    def __init__(self, session: Session):
        self.session = session

    def crear_clase(self, clase: Clase) -> Clase:
        self.session.add(clase)
        self.session.commit()
        self.session.refresh(clase)
        return clase

    def consultar_clase(self, clase_id: int) -> Optional[Clase]:
        return self.session.get(Clase, clase_id)

    def obtener_clase_por_id(self, clase_id: int) -> Optional[Clase]:
        return self.session.get(Clase, clase_id)
     
    def listar_clases_por_dia_hora(self, dia_semana: str, hora: str) -> List[Clase]:
        query = select(Clase).where(
            Clase.activa == True,
            Clase.hora == hora
        )
        clases = self.session.exec(query).all()
        return [c for c in clases if c.dias_semana and dia_semana in c.dias_semana]
    
    def obtener_clase_por_nombre(self, nombre: str) -> Optional[Clase]:
        statement = select(Clase).where(Clase.nombre == nombre)
        return self.session.exec(statement).first()

    def listar_clases(self, activas: bool = True, instructor: Optional[str] = None, horario: Optional[str] = None) -> List[Clase]:
        query = select(Clase)
        
        if activas:
            query = query.where(Clase.activa == True)
        
        if instructor:
            query = query.where(Clase.instructor == instructor)
        
        if horario:
            query = query.where(Clase.hora == horario)
        
        query = query.order_by(Clase.nombre)
        
        return self.session.exec(query).all()

    def listar_clases_por_instructor(self, instructor: str) -> List[Clase]:
        statement = select(Clase).where(Clase.instructor == instructor)
        return self.session.exec(statement).all()

    def listar_clases_por_dificultad(self, dificultad: str, activas: bool = True) -> List[Clase]:
        query = select(Clase).where(Clase.dificultad == dificultad)
        
        if activas:
            query = query.where(Clase.activa == True)
        
        return self.session.exec(query).all()

    def listar_clases_por_horario(self, horario: str, activas: bool = True) -> List[Clase]:
        query = select(Clase).where(Clase.hora == horario)
        if activas:
            query = query.where(Clase.activa == True)
        return self.session.exec(query).all()

    def actualizar_clase(self, clase_id: int, datos_actualizados: dict) -> Optional[Clase]:
        clase = self.consultar_clase(clase_id)
        if not clase:
            return None
        
        for key, value in datos_actualizados.items():
            if key == "dias_semana":
                if value is None:
                    value = []
                elif not isinstance(value, list):
                    value = list(value)
            setattr(clase, key, value)

        self.session.add(clase)
        self.session.commit()
        self.session.refresh(clase)
        return clase

    def eliminar_clase(self, clase_id: int) -> bool:
        clase = self.consultar_clase(clase_id)
        if clase:
            clase.activa = False  # Soft delete
            self.session.add(clase)
            self.session.commit()
            return True
        return False

    def activar_clase(self, clase_id: int) -> Optional[Clase]:
        clase = self.consultar_clase(clase_id)
        if clase:
            clase.activa = True
            self.session.add(clase)
            self.session.commit()
            self.session.refresh(clase)
        return clase

    def verificar_nombre_existente(self, nombre: str, excluir_id: Optional[int] = None) -> bool:
        query = select(Clase).where(Clase.nombre == nombre)
        
        if excluir_id:
            query = query.where(Clase.id != excluir_id)
        
        return self.session.exec(query).first() is not None

    # NUEVO MÉTODO: Obtener inscripciones activas para una clase
    def obtener_inscripciones_activas(self, clase_id: int) -> List:
        from models.inscripcion import Inscripcion, EstadoInscripcion
        statement = select(Inscripcion).where(
            Inscripcion.clase_id == clase_id,
            Inscripcion.estado == EstadoInscripcion.ACTIVO
        )
        return self.session.exec(statement).all()

    # NUEVO MÉTODO: Obtener todas las clases (incluyendo inactivas) para admin
    def listar_todas_las_clases(self, instructor: Optional[str] = None) -> List[Clase]:
        query = select(Clase)
        
        if instructor:
            query = query.where(Clase.instructor == instructor)
        
        query = query.order_by(Clase.activa.desc(), Clase.nombre)
        
        return self.session.exec(query).all()

    # NUEVO MÉTODO: Estadísticas de una clase
    def obtener_estadisticas_clase(self, clase_id: int) -> Dict[str, Any]:
        from models.inscripcion import Inscripcion, EstadoInscripcion
        from sqlalchemy import func
        
        clase = self.consultar_clase(clase_id)
        if not clase:
            return {}
        
        # Contar inscripciones activas
        inscripciones_activas = len(self.obtener_inscripciones_activas(clase_id))
        
        # Contar total de inscripciones históricas
        statement_total = select(func.count(Inscripcion.id)).where(Inscripcion.clase_id == clase_id)
        total_inscripciones = self.session.exec(statement_total).first()
        
        return {
            'clase_id': clase_id,
            'nombre': clase.nombre,
            'cupo_maximo': clase.cupo_maximo,
            'inscripciones_activas': inscripciones_activas,
            'cupos_disponibles': clase.cupo_maximo - inscripciones_activas,
            'porcentaje_ocupacion': (inscripciones_activas / clase.cupo_maximo * 100) if clase.cupo_maximo > 0 else 0,
            'total_inscripciones_historicas': total_inscripciones or 0
        }