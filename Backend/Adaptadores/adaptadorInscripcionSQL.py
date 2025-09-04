from models.inscripcion import Inscripcion, EstadoInscripcion
from sqlmodel import Session, select, func
from typing import List, Optional
from Dominio.repositorios.repositorioInscripciones import RepositorioInscripciones

class AdaptadorInscripcionesSQL(RepositorioInscripciones):
    def __init__(self, session: Session):
        self.session = session

    def crear_inscripcion(self, inscripcion: Inscripcion) -> Inscripcion:
        print(f"DEBUG ADAPTADOR: Creando inscripción para cliente {inscripcion.cliente_dni} en clase {inscripcion.clase_id}")
        self.session.add(inscripcion)
        self.session.commit()
        self.session.refresh(inscripcion)
        print(f"DEBUG ADAPTADOR: Inscripción {inscripcion.id} creada exitosamente")
        return inscripcion

    def consultar_inscripcion(self, inscripcion_id: int) -> Optional[Inscripcion]:
        print(f"DEBUG ADAPTADOR: Consultando inscripción ID {inscripcion_id}")
        inscripcion = self.session.get(Inscripcion, inscripcion_id)
        if inscripcion:
            print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} encontrada")
        else:
            print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} NO encontrada")
        return inscripcion

    def actualizar_inscripcion(self, inscripcion_id: int, datos_actualizacion: dict) -> Optional[Inscripcion]:
        print(f"DEBUG ADAPTADOR: Actualizando inscripción ID {inscripcion_id} con datos: {datos_actualizacion}")
        inscripcion = self.session.get(Inscripcion, inscripcion_id)
        if not inscripcion:
            print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} no encontrada para actualizar")
            return None
        
        for key, value in datos_actualizacion.items():
            setattr(inscripcion, key, value)
        
        self.session.add(inscripcion)
        self.session.commit()
        self.session.refresh(inscripcion)
        print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} actualizada exitosamente")
        return inscripcion

    def eliminar_inscripcion(self, inscripcion_id: int) -> bool:
        print(f"DEBUG ADAPTADOR: Eliminando inscripción ID {inscripcion_id}")
        inscripcion = self.session.get(Inscripcion, inscripcion_id)
        if not inscripcion:
            print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} no encontrada para eliminar")
            return False
        
        self.session.delete(inscripcion)
        self.session.commit()
        print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} eliminada exitosamente")
        return True

    def cancelar_inscripcion(self, inscripcion_id: int, motivo: Optional[str] = None) -> bool:
        from datetime import datetime
        print(f"DEBUG ADAPTADOR: Cancelando inscripción ID {inscripcion_id}, motivo: {motivo}")
        inscripcion = self.session.get(Inscripcion, inscripcion_id)
        if inscripcion:
            inscripcion.estado = EstadoInscripcion.CANCELADO
            inscripcion.fecha_cancelacion = datetime.utcnow()
            inscripcion.motivo_cancelacion = motivo
            self.session.add(inscripcion)
            self.session.commit()
            print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} cancelada exitosamente")
            return True
        print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} no encontrada para cancelar")
        return False

    def completar_inscripcion(self, inscripcion_id: int) -> bool:
        print(f"DEBUG ADAPTADOR: Completando inscripción ID {inscripcion_id}")
        inscripcion = self.session.get(Inscripcion, inscripcion_id)
        if inscripcion:
            inscripcion.estado = EstadoInscripcion.COMPLETADO
            self.session.add(inscripcion)
            self.session.commit()
            print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} marcada como completada")
            return True
        print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} no encontrada para completar")
        return False

    def ver_inscripciones_cliente(self, cliente_dni: str) -> List[Inscripcion]:
        print(f"DEBUG ADAPTADOR: Buscando inscripciones para cliente DNI: {cliente_dni}")
        statement = select(Inscripcion).where(Inscripcion.cliente_dni == cliente_dni)
        resultados = list(self.session.exec(statement))
        print(f"DEBUG ADAPTADOR: Encontradas {len(resultados)} inscripciones para cliente {cliente_dni}")
        return resultados

    def ver_inscripciones_clase(self, clase_id: int) -> List[Inscripcion]:
        print(f"DEBUG ADAPTADOR: Buscando inscripciones para clase ID: {clase_id}")
        statement = select(Inscripcion).where(Inscripcion.clase_id == clase_id)
        resultados = list(self.session.exec(statement))
        print(f"DEBUG ADAPTADOR: Encontradas {len(resultados)} inscripciones para clase {clase_id}")
        return resultados

    def listar_inscripciones(self, estado: Optional[EstadoInscripcion] = None, 
                           cliente_dni: Optional[str] = None, 
                           clase_id: Optional[int] = None) -> List[Inscripcion]:
        print(f"DEBUG ADAPTADOR: Listando inscripciones con filtros - estado={estado}, cliente_dni={cliente_dni}, clase_id={clase_id}")
        
        query = select(Inscripcion)
        
        if estado:
            query = query.where(Inscripcion.estado == estado)
            print(f"DEBUG ADAPTADOR: Aplicando filtro estado={estado}")
        
        if cliente_dni:
            query = query.where(Inscripcion.cliente_dni == cliente_dni)
            print(f"DEBUG ADAPTADOR: Aplicando filtro cliente_dni={cliente_dni}")
        
        if clase_id:
            query = query.where(Inscripcion.clase_id == clase_id)
            print(f"DEBUG ADAPTADOR: Aplicando filtro clase_id={clase_id}")
        
        query = query.order_by(Inscripcion.fecha_inscripcion.desc())
        
        resultados = list(self.session.exec(query))
        print(f"DEBUG ADAPTADOR: Query retornó {len(resultados)} resultados")
        
        # Debug detallado de los resultados
        for i, inscripcion in enumerate(resultados):
            print(f"DEBUG ADAPTADOR: Resultado {i+1} - ID: {inscripcion.id}, Cliente: {inscripcion.cliente_dni}, Clase: {inscripcion.clase_id}, Estado: {inscripcion.estado}")
        
        return resultados

    def marcar_pagado(self, inscripcion_id: int) -> bool:
        print(f"DEBUG ADAPTADOR: Marcando como pagado inscripción ID {inscripcion_id}")
        inscripcion = self.session.get(Inscripcion, inscripcion_id)
        if inscripcion:
            inscripcion.pagado = True
            self.session.add(inscripcion)
            self.session.commit()
            print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} marcada como pagada")
            return True
        print(f"DEBUG ADAPTADOR: Inscripción {inscripcion_id} no encontrada para marcar como pagada")
        return False

    def obtener_estadisticas(self) -> dict:
        print("DEBUG ADAPTADOR: Obteniendo estadísticas de inscripciones")
        
        total = self.session.exec(select(func.count(Inscripcion.id))).one()
        activas = self.session.exec(select(func.count(Inscripcion.id)).where(Inscripcion.estado == EstadoInscripcion.ACTIVO)).one()
        canceladas = self.session.exec(select(func.count(Inscripcion.id)).where(Inscripcion.estado == EstadoInscripcion.CANCELADO)).one()
        completadas = self.session.exec(select(func.count(Inscripcion.id)).where(Inscripcion.estado == EstadoInscripcion.COMPLETADO)).one()
        pendientes = self.session.exec(select(func.count(Inscripcion.id)).where(Inscripcion.estado == EstadoInscripcion.PENDIENTE)).one()
        
        estadisticas = {
            "total_inscripciones": total,
            "activas": activas,
            "canceladas": canceladas,
            "completadas": completadas,
            "pendientes": pendientes
        }
        
        print(f"DEBUG ADAPTADOR: Estadísticas obtenidas: {estadisticas}")
        return estadisticas