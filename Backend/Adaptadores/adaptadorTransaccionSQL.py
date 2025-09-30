from models.transaccion import Transaccion, EstadoPago, MetodoPago
from sqlmodel import Session, select, func
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from Dominio.repositorios.repositorioTransaccion import RepositorioTransaccion

class AdaptadorTransaccionSQL(RepositorioTransaccion):
    def __init__(self, session: Session):
        self.session = session

    def crear_transaccion(self, transaccion: Transaccion) -> Transaccion:
        self.session.add(transaccion)
        self.session.commit()
        self.session.refresh(transaccion)
        return transaccion
    
    def listar_todas_las_transacciones(self):
        """Listar todas las transacciones"""
        with self.session as session:
            statement = select(Transaccion)
        return session.exec(statement).all()

    def consultar_transaccion_completa(self, transaccion_id: int):
        """Obtener transacción con información completa"""
        return self.consultar_transaccion(transaccion_id)

    def consultar_transaccion_por_referencia_completa(self, referencia: str):
        """Obtener transacción por referencia con información completa"""
        return self.consultar_transaccion_por_referencia(referencia)

    def marcar_como_pagada_manual(self, transaccion_id: int, referencia_pago: str = None):
        """Marcar transacción como pagada manualmente"""
        with self.session as session:
            transaccion = session.get(Transaccion, transaccion_id)
            if transaccion:
                transaccion.estado = EstadoPago.COMPLETADO
                transaccion.fecha_actualizacion = datetime.now()
                if referencia_pago:
                    transaccion.referencia_pago = referencia_pago
                session.add(transaccion)
                session.commit()
                session.refresh(transaccion)
            return transaccion
        
    def revertir_transaccion(self, transaccion_id: int, motivo: str):
        """Revertir una transacción completada"""
        with self.session as session:
            transaccion = session.get(Transaccion, transaccion_id)
            if transaccion and transaccion.estado == EstadoPago.COMPLETADO:
                transaccion.estado = EstadoPago.RECHAZADO
                transaccion.observaciones = f"Revertida: {motivo}"
                transaccion.fecha_actualizacion = datetime.now()
                session.add(transaccion)
                session.commit()
                session.refresh(transaccion)
            return transaccion

    def actualizar_transaccion(self, transaccion_id: int, datos_actualizacion: Dict[str, Any]) -> Optional[Transaccion]:
        transaccion = self.session.get(Transaccion, transaccion_id)
        if not transaccion:
            return None
        
        for key, value in datos_actualizacion.items():
            setattr(transaccion, key, value)
        
        # Actualizar fecha de modificación
        transaccion.fecha_actualizacion = datetime.utcnow()
        
        self.session.add(transaccion)
        self.session.commit()
        self.session.refresh(transaccion)
        return transaccion

    def eliminar_transaccion_permanentemente(self, transaccion_id: int) -> bool:
        """Eliminar transacción permanentemente"""
        with self.session as session:
            transaccion = session.get(Transaccion, transaccion_id)
            if transaccion:
                session.delete(transaccion)
                session.commit()
                return True
            return False

    def cambiar_estado_transaccion(self, transaccion_id: int, estado: EstadoPago, observaciones: Optional[str] = None) -> bool:
        transaccion = self.session.get(Transaccion, transaccion_id)
        if not transaccion:
            return False
        
        transaccion.estado = estado
        if observaciones:
            transaccion.observaciones = observaciones
        transaccion.fecha_actualizacion = datetime.utcnow()
        
        self.session.add(transaccion)
        self.session.commit()
        return True

    def abrir_url_comprobante(self, transaccion_id: int) -> Optional[str]:
        transaccion = self.session.get(Transaccion, transaccion_id)
        if transaccion:
            return transaccion.url_comprobante
        return None

    def ver_historial_transacciones(self, cliente_dni: str) -> List[Transaccion]:
        statement = select(Transaccion).where(Transaccion.cliente_dni == cliente_dni)
        return list(self.session.exec(statement))


    
    def ver_transacciones_ultimo_mes(self, cliente_dni: str) -> List[Transaccion]:
        un_mes_atras = datetime.utcnow() - timedelta(days=30)
        query = select(Transaccion).where(
            (Transaccion.cliente_dni == cliente_dni) & 
            (Transaccion.fecha >= un_mes_atras)
        ).order_by(Transaccion.fecha.desc())
        return list(self.session.exec(query))
    
    def listar_transacciones(self, 
                           estado: Optional[EstadoPago] = None,
                           cliente_dni: Optional[str] = None,
                           metodo_pago: Optional[MetodoPago] = None,
                           fecha_inicio: Optional[datetime] = None,
                           fecha_fin: Optional[datetime] = None) -> List[Transaccion]:
        query = select(Transaccion)
        
        if estado:
            query = query.where(Transaccion.estado == estado)
        
        if cliente_dni:
            query = query.where(Transaccion.cliente_dni == cliente_dni)
        
        if metodo_pago:
            query = query.where(Transaccion.metodo_pago == metodo_pago)
        
        if fecha_inicio:
            query = query.where(Transaccion.fecha >= fecha_inicio)
        
        if fecha_fin:
            query = query.where(Transaccion.fecha <= fecha_fin)
        
        query = query.order_by(Transaccion.fecha.desc())
        
        return list(self.session.exec(query))

    def obtener_estadisticas_avanzadas(self):
        """Estadísticas avanzadas de transacciones"""
        transacciones = self.listar_todas_las_transacciones()
        
        return {
            "total": len(transacciones),
            "pendientes": len([t for t in transacciones if t.estado == EstadoPago.PENDIENTE]),
            "completadas": len([t for t in transacciones if t.estado == EstadoPago.COMPLETADO]),
            "rechazadas": len([t for t in transacciones if t.estado == EstadoPago.RECHAZADO]),
            "monto_total": sum(t.monto for t in transacciones),
            "monto_pendiente": sum(t.monto for t in transacciones if t.estado == EstadoPago.PENDIENTE),
            "monto_completado": sum(t.monto for t in transacciones if t.estado == EstadoPago.COMPLETADO)
        }

    def generar_reporte_diario(self, fecha: datetime):
        """Generar reporte diario"""
        transacciones_dia = self.listar_transacciones_por_fecha(fecha)
        
        return {
            "total_transacciones": len(transacciones_dia),
            "monto_total": sum(t.monto for t in transacciones_dia),
            "por_estado": self._agrupar_por_estado(transacciones_dia)
        }

    def generar_reporte_metodos_pago_detallado(self, fecha_inicio: datetime, fecha_fin: datetime):
        """Generar reporte detallado por método de pago"""
        transacciones_periodo = [t for t in self.listar_todas_las_transacciones() 
                            if fecha_inicio <= t.fecha_creacion <= fecha_fin]
        
        return self._agrupar_por_metodo_pago(transacciones_periodo)


    def ver_transacciones_ultimo_mes(self, cliente_dni: str) -> List[Transaccion]:
        fecha_limite = datetime.utcnow() - timedelta(days=30)
        
        query = select(Transaccion).where(
            Transaccion.cliente_dni == cliente_dni,
            Transaccion.fecha >= fecha_limite
        ).order_by(Transaccion.fecha.desc())
        
        return list(self.session.exec(query))
    
    def ver_historial_completo_cliente(self, cliente_dni: str, limite: int = 100):
        """Ver historial completo del cliente"""
        with self.session as session:
            statement = (select(Transaccion)
                        .where(Transaccion.cliente_dni == cliente_dni)
                        .order_by(Transaccion.fecha_creacion.desc())
                        .limit(limite))
            return session.exec(statement).all()

    def obtener_transacciones_pendientes_antiguas(self, horas_limite: int):
        """Obtener transacciones pendientes por mucho tiempo"""
        limite_tiempo = datetime.now() - timedelta(hours=horas_limite)
        
        with self.session as session:
            statement = (select(Transaccion)
                        .where(Transaccion.estado == EstadoPago.PENDIENTE)
                        .where(Transaccion.fecha_creacion <= limite_tiempo))
            return session.exec(statement).all()

    def busqueda_avanzada(self, **filtros):
        """Búsqueda avanzada con múltiples parámetros"""
        with self.session as session:
            query = select(Transaccion)
            
            if filtros.get('referencia'):
                query = query.where(Transaccion.referencia.contains(filtros['referencia']))
            if filtros.get('cliente_dni'):
                query = query.where(Transaccion.cliente_dni == filtros['cliente_dni'])
            if filtros.get('estado'):
                query = query.where(Transaccion.estado == filtros['estado'])
            if filtros.get('metodo_pago'):
                query = query.where(Transaccion.metodo_pago == filtros['metodo_pago'])
            if filtros.get('monto_minimo') is not None:
                query = query.where(Transaccion.monto >= filtros['monto_minimo'])
            if filtros.get('monto_maximo') is not None:
                query = query.where(Transaccion.monto <= filtros['monto_maximo'])
            if filtros.get('fecha_inicio'):
                query = query.where(Transaccion.fecha_creacion >= filtros['fecha_inicio'])
            if filtros.get('fecha_fin'):
                query = query.where(Transaccion.fecha_creacion <= filtros['fecha_fin'])
            
            return session.exec(query).all()

    def obtener_estadisticas_dashboard(self):
        """Estadísticas para dashboard"""
        return self.obtener_estadisticas_avanzadas()

    def obtener_ultimas_transacciones(self, limit: int = 10):
        """Obtener últimas transacciones"""
        with self.session as session:
            statement = (select(Transaccion)
                        .order_by(Transaccion.fecha_creacion.desc())
                        .limit(limit))
            return session.exec(statement).all()

    def _agrupar_por_estado(self, transacciones):
        """Agrupar transacciones por estado"""
        agrupado = {}
        for t in transacciones:
            if t.estado not in agrupado:
                agrupado[t.estado] = []
            agrupado[t.estado].append(t)
        return agrupado

    def _agrupar_por_metodo_pago(self, transacciones):
        """Agrupar transacciones por método de pago"""
        agrupado = {}
        for t in transacciones:
            if t.metodo_pago not in agrupado:
                agrupado[t.metodo_pago] = {"count": 0, "monto_total": 0}
            agrupado[t.metodo_pago]["count"] += 1
            agrupado[t.metodo_pago]["monto_total"] += t.monto
        return agrupado

    # Métodos para cumplir con la interfaz RepositorioTransaccion
    def consultar_transaccion(self, transaccion_id: int) -> Optional[Transaccion]:
        return self.session.get(Transaccion, transaccion_id)

    def consultar_transaccion_por_referencia(self, referencia: str) -> Optional[Transaccion]:
        statement = select(Transaccion).where(Transaccion.referencia == referencia)
        result = self.session.exec(statement).first()
        return result

    def eliminar_transaccion(self, transaccion_id: int) -> bool:
        return self.eliminar_transaccion_permanentemente(transaccion_id)

    def obtener_estadisticas_metodos_pago(self) -> List[Dict[str, Any]]:
        transacciones = self.listar_todas_las_transacciones()
        agrupado = self._agrupar_por_metodo_pago(transacciones)
        resultado = []
        for metodo, datos in agrupado.items():
            resultado.append({
                "metodo": metodo,
                "count": datos["count"],
                "monto_total": datos["monto_total"]
            })
        return resultado

    def obtener_estadisticas_totales(self) -> Dict[str, Any]:
        estadisticas = self.obtener_estadisticas_avanzadas()
        return estadisticas

    def ver_todas(self) -> List[Transaccion]:
        return self.listar_todas_las_transacciones()