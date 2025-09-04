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

    def consultar_transaccion(self, transaccion_id: int) -> Optional[Transaccion]:
        return self.session.get(Transaccion, transaccion_id)

    def consultar_transaccion_por_referencia(self, referencia: str) -> Optional[Transaccion]:
        return self.session.exec(select(Transaccion).where(Transaccion.referencia == referencia)).first()

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

    def eliminar_transaccion(self, transaccion_id: int) -> bool:
        transaccion = self.session.get(Transaccion, transaccion_id)
        if not transaccion:
            return False
        
        self.session.delete(transaccion)
        self.session.commit()
        return True

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

    def ver_todas(self) -> List[Transaccion]:
        statement = select(Transaccion)
        return list(self.session.exec(statement))

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

    def obtener_estadisticas_totales(self) -> Dict[str, Any]:
        total = self.session.exec(select(func.count(Transaccion.id))).one()
        pendientes = self.session.exec(select(func.count(Transaccion.id)).where(Transaccion.estado == EstadoPago.PENDIENTE)).one()
        completadas = self.session.exec(select(func.count(Transaccion.id)).where(Transaccion.estado == EstadoPago.COMPLETADO)).one()
        rechazadas = self.session.exec(select(func.count(Transaccion.id)).where(Transaccion.estado == EstadoPago.RECHAZADO)).one()
        
        monto_total = self.session.exec(select(func.sum(Transaccion.monto))).one() or 0.0
        monto_pendiente = self.session.exec(select(func.sum(Transaccion.monto)).where(Transaccion.estado == EstadoPago.PENDIENTE)).one() or 0.0
        monto_completado = self.session.exec(select(func.sum(Transaccion.monto)).where(Transaccion.estado == EstadoPago.COMPLETADO)).one() or 0.0
        
        return {
            "total": total,
            "pendientes": pendientes,
            "completadas": completadas,
            "rechazadas": rechazadas,
            "monto_total": monto_total,
            "monto_pendiente": monto_pendiente,
            "monto_completado": monto_completado
        }

    def obtener_estadisticas_metodos_pago(self) -> List[Dict[str, Any]]:
        metodos = self.session.exec(select(Transaccion.metodo_pago).distinct()).all()
        
        resultado = []
        for metodo in metodos:
            cantidad = self.session.exec(select(func.count(Transaccion.id)).where(Transaccion.metodo_pago == metodo)).one()
            monto_total = self.session.exec(select(func.sum(Transaccion.monto)).where(Transaccion.metodo_pago == metodo)).one() or 0.0
            
            resultado.append({
                "metodo": metodo,
                "cantidad": cantidad,
                "monto_total": monto_total
            })
        
        return resultado

    def ver_transacciones_ultimo_mes(self, cliente_dni: str) -> List[Transaccion]:
        fecha_limite = datetime.utcnow() - timedelta(days=30)
        
        query = select(Transaccion).where(
            Transaccion.cliente_dni == cliente_dni,
            Transaccion.fecha >= fecha_limite
        ).order_by(Transaccion.fecha.desc())
        
        return list(self.session.exec(query))