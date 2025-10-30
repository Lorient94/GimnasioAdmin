# Adaptadores/adaptadorTransaccionSQL.py - VERSIÓN COMPLETA
from models.transaccion import Transaccion, EstadoTransaccion, MetodoPago, EstadoPago, convertir_estado_pago_a_transaccion, convertir_estado_transaccion_a_pago
from sqlmodel import Session, select, func
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from Dominio.repositorios.repositorioTransaccion import RepositorioTransaccion

class AdaptadorTransaccionSQL(RepositorioTransaccion):
    def __init__(self, session: Session):
        self.session = session

    # ✅ MÉTODOS OBLIGATORIOS DE LA INTERFAZ
    def crear_transaccion(self, transaccion: Transaccion) -> Transaccion:
        self.session.add(transaccion)
        self.session.commit()
        self.session.refresh(transaccion)
        return transaccion

    def consultar_transaccion(self, transaccion_id: int) -> Optional[Transaccion]:
        return self.session.get(Transaccion, transaccion_id)

    def consultar_transaccion_por_referencia(self, referencia: str) -> Optional[Transaccion]:
        statement = select(Transaccion).where(Transaccion.referencia == referencia)
        return self.session.exec(statement).first()

    def actualizar_transaccion(self, transaccion_id: int, datos_actualizacion: Dict[str, Any]) -> Optional[Transaccion]:
        transaccion = self.consultar_transaccion(transaccion_id)
        if not transaccion:
            return None
        
        # Convertir EstadoPago a EstadoTransaccion si es necesario
        if 'estado' in datos_actualizacion and isinstance(datos_actualizacion['estado'], EstadoPago):
            datos_actualizacion['estado'] = convertir_estado_pago_a_transaccion(datos_actualizacion['estado'])
        
        for key, value in datos_actualizacion.items():
            setattr(transaccion, key, value)
        
        transaccion.fecha_actualizacion = datetime.utcnow()
        
        self.session.add(transaccion)
        self.session.commit()
        self.session.refresh(transaccion)
        return transaccion

    def eliminar_transaccion(self, transaccion_id: int) -> bool:
        transaccion = self.consultar_transaccion(transaccion_id)
        if not transaccion:
            return False
        
        self.session.delete(transaccion)
        self.session.commit()
        return True

    def cambiar_estado_transaccion(self, transaccion_id: int, estado: EstadoPago, observaciones: Optional[str] = None) -> bool:
        transaccion = self.consultar_transaccion(transaccion_id)
        if not transaccion:
            return False
        
        # Convertir EstadoPago a EstadoTransaccion
        estado_transaccion = convertir_estado_pago_a_transaccion(estado)
        transaccion.estado = estado_transaccion
        if observaciones:
            transaccion.observaciones = observaciones
        transaccion.fecha_actualizacion = datetime.utcnow()
        
        self.session.add(transaccion)
        self.session.commit()
        return True

    def abrir_url_comprobante(self, transaccion_id: int) -> Optional[str]:
        """Obtener URL del comprobante de la transacción"""
        transaccion = self.consultar_transaccion(transaccion_id)
        if transaccion:
            return transaccion.url_comprobante
        return None

    def ver_historial_transacciones(self, cliente_dni: str) -> List[Transaccion]:
        """Ver historial de transacciones de un cliente"""
        statement = select(Transaccion).where(Transaccion.cliente_dni == cliente_dni)
        return list(self.session.exec(statement))

    def ver_todas(self) -> List[Transaccion]:
        """Ver todas las transacciones"""
        return self.session.exec(select(Transaccion)).all()

    def listar_transacciones(self, 
                           estado: Optional[EstadoPago] = None,
                           cliente_dni: Optional[str] = None,
                           metodo_pago: Optional[MetodoPago] = None,
                           fecha_inicio: Optional[datetime] = None,
                           fecha_fin: Optional[datetime] = None) -> List[Transaccion]:
        """Listar transacciones con filtros"""
        query = select(Transaccion)
        
        if estado:
            # Convertir EstadoPago a EstadoTransaccion para la consulta
            estado_transaccion = convertir_estado_pago_a_transaccion(estado)
            query = query.where(Transaccion.estado == estado_transaccion)
        
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

    def obtener_estadisticas_totales(self) -> Dict[str, Any]:
        """Obtener estadísticas totales de transacciones"""
        transacciones = self.ver_todas()
        
        return {
            "total": len(transacciones),
            "pendientes": len([t for t in transacciones if t.estado == EstadoTransaccion.PENDIENTE]),
            "completadas": len([t for t in transacciones if t.estado == EstadoTransaccion.COMPLETADA]),
            "rechazadas": len([t for t in transacciones if t.estado == EstadoTransaccion.RECHAZADA]),
            "monto_total": sum(t.monto for t in transacciones),
            "monto_pendiente": sum(t.monto for t in transacciones if t.estado == EstadoTransaccion.PENDIENTE),
            "monto_completado": sum(t.monto for t in transacciones if t.estado == EstadoTransaccion.COMPLETADA)
        }

    def obtener_estadisticas_metodos_pago(self) -> List[Dict[str, Any]]:
        """Obtener estadísticas por método de pago"""
        transacciones = self.ver_todas()
        agrupado = self._agrupar_por_metodo_pago(transacciones)
        resultado = []
        for metodo, datos in agrupado.items():
            resultado.append({
                "metodo": metodo,
                "count": datos["count"],
                "monto_total": datos["monto_total"]
            })
        return resultado

    def ver_transacciones_ultimo_mes(self, cliente_dni: str) -> List[Transaccion]:
        """Ver transacciones del último mes de un cliente"""
        un_mes_atras = datetime.utcnow() - timedelta(days=30)
        query = select(Transaccion).where(
            (Transaccion.cliente_dni == cliente_dni) & 
            (Transaccion.fecha >= un_mes_atras)
        ).order_by(Transaccion.fecha.desc())
        return list(self.session.exec(query))

    # ✅ MÉTODOS ADICIONALES PARA EL ROUTER
    def listar_todas_las_transacciones(self):
        """Listar todas las transacciones"""
        return self.ver_todas()

    def consultar_transaccion_completa(self, transaccion_id: int):
        """Obtener transacción con información completa"""
        return self.consultar_transaccion(transaccion_id)

    def consultar_transaccion_por_referencia_completa(self, referencia: str):
        """Obtener transacción por referencia con información completa"""
        return self.consultar_transaccion_por_referencia(referencia)

    def marcar_como_pagada_manual(self, transaccion_id: int, referencia_pago: str = None):
        """Marcar transacción como pagada manualmente"""
        transaccion = self.session.get(Transaccion, transaccion_id)
        if transaccion:
            transaccion.estado = EstadoTransaccion.COMPLETADA
            transaccion.fecha_actualizacion = datetime.now()
            if referencia_pago:
                transaccion.referencia = referencia_pago
            self.session.add(transaccion)
            self.session.commit()
            self.session.refresh(transaccion)
        return transaccion
        
    def revertir_transaccion(self, transaccion_id: int, motivo: str):
        """Revertir una transacción completada"""
        transaccion = self.session.get(Transaccion, transaccion_id)
        if transaccion and transaccion.estado == EstadoTransaccion.COMPLETADA:
            transaccion.estado = EstadoTransaccion.REEMBOLSADA
            transaccion.observaciones = f"Revertida: {motivo}"
            transaccion.fecha_actualizacion = datetime.now()
            self.session.add(transaccion)
            self.session.commit()
            self.session.refresh(transaccion)
        return transaccion

    def eliminar_transaccion_permanentemente(self, transaccion_id: int) -> bool:
        """Eliminar transacción permanentemente"""
        return self.eliminar_transaccion(transaccion_id)

    def obtener_estadisticas_avanzadas(self):
        """Estadísticas avanzadas de transacciones"""
        return self.obtener_estadisticas_totales()

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
        transacciones_periodo = [t for t in self.ver_todas() 
                            if fecha_inicio <= t.fecha <= fecha_fin]
        
        return self._agrupar_por_metodo_pago(transacciones_periodo)
    
    def ver_historial_completo_cliente(self, cliente_dni: str, limite: int = 100):
        """Ver historial completo del cliente"""
        statement = (select(Transaccion)
                    .where(Transaccion.cliente_dni == cliente_dni)
                    .order_by(Transaccion.fecha.desc())
                    .limit(limite))
        return self.session.exec(statement).all()

    def obtener_transacciones_pendientes_antiguas(self, horas_limite: int):
        """Obtener transacciones pendientes por mucho tiempo"""
        limite_tiempo = datetime.now() - timedelta(hours=horas_limite)
        
        statement = (select(Transaccion)
                    .where(Transaccion.estado == EstadoTransaccion.PENDIENTE)
                    .where(Transaccion.fecha <= limite_tiempo))
        return self.session.exec(statement).all()

    def busqueda_avanzada(self, **filtros):
        """Búsqueda avanzada con múltiples parámetros"""
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
            query = query.where(Transaccion.fecha >= filtros['fecha_inicio'])
        if filtros.get('fecha_fin'):
            query = query.where(Transaccion.fecha <= filtros['fecha_fin'])
        
        return self.session.exec(query).all()

    def obtener_estadisticas_dashboard(self):
        """Estadísticas para dashboard"""
        return self.obtener_estadisticas_totales()

    def obtener_ultimas_transacciones(self, limit: int = 10):
        """Obtener últimas transacciones"""
        statement = (select(Transaccion)
                    .order_by(Transaccion.fecha.desc())
                    .limit(limit))
        return self.session.exec(statement).all()

    def listar_transacciones_por_fecha(self, fecha: datetime):
        """Listar transacciones por fecha específica"""
        inicio_dia = fecha.replace(hour=0, minute=0, second=0, microsecond=0)
        fin_dia = fecha.replace(hour=23, minute=59, second=59, microsecond=999999)
        
        statement = (select(Transaccion)
                    .where(Transaccion.fecha >= inicio_dia)
                    .where(Transaccion.fecha <= fin_dia))
        return self.session.exec(statement).all()

    def generar_reporte_mensual(self, año: int, mes: int):
        """Generar reporte mensual"""
        inicio_mes = datetime(año, mes, 1)
        if mes == 12:
            fin_mes = datetime(año + 1, 1, 1) - timedelta(seconds=1)
        else:
            fin_mes = datetime(año, mes + 1, 1) - timedelta(seconds=1)
        
        transacciones_mes = [t for t in self.ver_todas() 
                           if inicio_mes <= t.fecha <= fin_mes]
        
        return {
            "total_transacciones": len(transacciones_mes),
            "monto_total": sum(t.monto for t in transacciones_mes),
            "por_estado": self._agrupar_por_estado(transacciones_mes),
            "por_metodo_pago": self._agrupar_por_metodo_pago(transacciones_mes)
        }

    # ✅ MÉTODOS AUXILIARES
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