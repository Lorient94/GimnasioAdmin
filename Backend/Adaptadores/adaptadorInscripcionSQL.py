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
    def consultar_inscripcion_completa(self, inscripcion_id: int):
        """Obtener inscripción con información completa"""
        return self.consultar_inscripcion(inscripcion_id)
    
    def listar_todas_las_inscripciones(self):
        """Listar todas las inscripciones, incluyendo históricas"""
        statement = select(Inscripcion)
        return self.session.exec(statement).all()
    
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

    def eliminar_inscripcion_permanentemente(self, inscripcion_id: int) -> bool:
        """Eliminar inscripción permanentemente"""
        with self.session as session:
            inscripcion = session.get(Inscripcion, inscripcion_id)
            if inscripcion:
                session.delete(inscripcion)
                session.commit()
                return True
            return False

    # Método requerido por la interfaz: proporcionar una versión pública (soft delete por defecto)
    def eliminar_inscripcion(self, inscripcion_id: int) -> bool:
        """Elimina (soft delete) o delega a la eliminación permanente según lógica de negocio."""
        # Por ahora implementamos soft-delete para mantener integridad de los registros
        inscripcion = self.session.get(Inscripcion, inscripcion_id)
        if inscripcion:
            try:
                inscripcion.estado = EstadoInscripcion.CANCELADO
                from datetime import datetime
                inscripcion.fecha_cancelacion = datetime.utcnow()
                self.session.add(inscripcion)
                self.session.commit()
                return True
            except Exception as e:
                print(f"Error realizando soft-delete en inscripcion {inscripcion_id}: {e}")
                return False
        return False

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

    def ver_inscripciones_cliente(self, cliente_dni: str, estado: EstadoInscripcion = EstadoInscripcion.ACTIVO):
        statement = select(Inscripcion).where(
        (Inscripcion.cliente_dni == cliente_dni) &
        (Inscripcion.estado == estado)
    )
        return list(self.session.exec(statement))
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
    
    def reactivar_inscripcion(self, inscripcion_id: int):
        """Reactivar una inscripción cancelada"""
        # CORREGIR: No usar 'with self.session as session'
        inscripcion = self.session.get(Inscripcion, inscripcion_id)
        if inscripcion:
            inscripcion.estado = EstadoInscripcion.ACTIVO  # Usar el enum, no string
            inscripcion.fecha_cancelacion = None
            inscripcion.motivo_cancelacion = None
            self.session.add(inscripcion)
            self.session.commit()
            self.session.refresh(inscripcion)
        return inscripcion

        
    def listar_inscripciones_historicas_cliente(self, cliente_dni: str):
        """Listar todas las inscripciones históricas de un cliente"""
        return self.ver_inscripciones_cliente(cliente_dni)

    def ver_inscripciones_clase_completas(self, clase_id: int):
        """Obtener inscripciones de una clase con información completa"""
        return self.ver_inscripciones_clase(clase_id)

    def obtener_estadisticas_avanzadas(self):
        """Estadísticas avanzadas de inscripciones"""
        inscripciones = self.listar_todas_las_inscripciones()
        
        return {
            "total_inscripciones": len(inscripciones),
            "activas": len([i for i in inscripciones if i.estado == EstadoInscripcion.ACTIVO]),
            "canceladas": len([i for i in inscripciones if i.estado == EstadoInscripcion.CANCELADO]),
            "completadas": len([i for i in inscripciones if i.estado == EstadoInscripcion.COMPLETADO]),
            # "por_mes": self._calcular_inscripciones_por_mes(inscripciones)  # Comentar si no existe
        }
    def _calcular_inscripciones_por_mes(self, inscripciones):
        """Calcular inscripciones por mes (placeholder)"""
        # Implementar lógica real según necesidad
        return {}

    def obtener_clases_populares(self):
        """Obtener clases más populares"""
        # Implementación básica - agrupar por clase_id
        inscripciones = self.listar_todas_las_inscripciones()
        clases_count = {}
        
        for inscripcion in inscripciones:
            if inscripcion.clase_id not in clases_count:
                clases_count[inscripcion.clase_id] = 0
            clases_count[inscripcion.clase_id] += 1
        
        return [{"clase_id": k, "total_inscripciones": v} for k, v in clases_count.items()]

    def obtener_clientes_activos(self):
        """Obtener clientes más activos"""
        inscripciones = self.listar_todas_las_inscripciones()
        clientes_count = {}
        
        for inscripcion in inscripciones:
            if inscripcion.cliente_dni not in clientes_count:
                clientes_count[inscripcion.cliente_dni] = 0
            clientes_count[inscripcion.cliente_dni] += 1
        
        return [{"cliente_dni": k, "total_inscripciones": v} for k, v in clientes_count.items()]

    def obtener_clases_cupo_critico(self, porcentaje_alerta):
        """Obtener clases con cupo crítico"""
        # Esto requiere información de clases, sería mejor en un servicio separado
        return []
    
    def obtener_clases_populares(self):
        """Obtener clases más populares"""
        # Implementar lógica para agrupar por clase
        pass

    def obtener_clientes_activos(self):
        """Obtener clientes más activos"""
        # Implementar lógica para agrupar por cliente
        pass

    def generar_reporte_temporal(self, fecha_inicio, fecha_fin):
        """Generar reporte por período"""
        inscripciones = self.listar_todas_las_inscripciones()
        inscripciones_periodo = [i for i in inscripciones if fecha_inicio <= i.fecha_inscripcion <= fecha_fin]
        
        return {
            "total_inscripciones": len(inscripciones_periodo),
            "nuevas_inscripciones": len([i for i in inscripciones_periodo if i.estado == "activo"]),
            "cancelaciones": len([i for i in inscripciones_periodo if i.estado == "cancelado"])
        }

    def obtener_clases_cupo_critico(self, porcentaje_alerta):
        """Obtener clases con cupo crítico"""
        # Implementar lógica de alertas de cupo
        pass

    def obtener_estadisticas_dashboard(self):
        """Estadísticas para dashboard"""
        return self.obtener_estadisticas_avanzadas()

    def obtener_ultimas_inscripciones(self, limit=10):
        """Obtener últimas inscripciones"""
        with self.session as session:
            statement = select(Inscripcion).order_by(Inscripcion.fecha_inscripcion.desc()).limit(limit)
            return session.exec(statement).all()