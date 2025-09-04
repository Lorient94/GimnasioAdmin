from models.pago import Pago, EstadoPago
from sqlmodel import Session, select, func
from typing import List, Optional, Dict, Any
from datetime import datetime
from Dominio.repositorios.repositorioPago import RepositorioPago

class AdaptadorPagoSQL(RepositorioPago):
    def __init__(self, session: Session):
        self.session = session

    def crear_pago(self, pago: Pago) -> Pago:
        self.session.add(pago)
        self.session.commit()
        self.session.refresh(pago)
        return pago

    def consultar_pago(self, pago_id: int) -> Optional[Pago]:
        return self.session.get(Pago, pago_id)

    def consultar_pago_por_referencia(self, referencia: str) -> Optional[Pago]:
        return self.session.exec(select(Pago).where(Pago.referencia == referencia)).first()

    def actualizar_pago(self, pago_id: int, datos_actualizacion: Dict[str, Any]) -> Optional[Pago]:
        pago = self.session.get(Pago, pago_id)
        if not pago:
            return None
        
        for key, value in datos_actualizacion.items():
            setattr(pago, key, value)
        
        # Actualizar fecha de modificación
        pago.fecha_actualizacion = datetime.utcnow()
        
        self.session.add(pago)
        self.session.commit()
        self.session.refresh(pago)
        return pago

    def eliminar_pago(self, pago_id: int) -> bool:
        pago = self.session.get(Pago, pago_id)
        if not pago:
            return False
        
        self.session.delete(pago)
        self.session.commit()
        return True

    def cambiar_estado_pago(self, pago_id: int, estado: EstadoPago, observaciones: Optional[str] = None) -> bool:
        pago = self.session.get(Pago, pago_id)
        if not pago:
            return False
        
        pago.estado_pago = estado
        if observaciones:
            pago.observaciones = observaciones
        pago.fecha_actualizacion = datetime.utcnow()
        
        self.session.add(pago)
        self.session.commit()
        return True

    def completar_pago(self, pago_id: int) -> bool:
        return self.cambiar_estado_pago(pago_id, EstadoPago.COMPLETADO)

    def rechazar_pago(self, pago_id: int) -> bool:
        return self.cambiar_estado_pago(pago_id, EstadoPago.RECHAZADO)

    def listar_pagos(self, 
                   estado_pago: Optional[EstadoPago] = None,
                   id_usuario: Optional[str] = None,
                   transaccion_id: Optional[int] = None) -> List[Pago]:
        query = select(Pago)
        
        if estado_pago:
            query = query.where(Pago.estado_pago == estado_pago)
        
        if id_usuario:
            query = query.where(Pago.id_usuario == id_usuario)
        
        if transaccion_id:
            query = query.where(Pago.transaccion_id == transaccion_id)
        
        query = query.order_by(Pago.fecha_creacion.desc())
        
        return list(self.session.exec(query))

    def obtener_pagos_usuario(self, usuario_dni: str) -> List[Pago]:
        query = select(Pago).where(Pago.id_usuario == usuario_dni).order_by(Pago.fecha_creacion.desc())
        return list(self.session.exec(query))

    def obtener_pagos_transaccion(self, transaccion_id: int) -> List[Pago]:
        query = select(Pago).where(Pago.transaccion_id == transaccion_id).order_by(Pago.fecha_creacion.desc())
        return list(self.session.exec(query))

    def obtener_estadisticas_totales(self) -> Dict[str, Any]:
        total = self.session.exec(select(func.count(Pago.id))).one()
        pendientes = self.session.exec(select(func.count(Pago.id)).where(Pago.estado_pago == EstadoPago.PENDIENTE)).one()
        completados = self.session.exec(select(func.count(Pago.id)).where(Pago.estado_pago == EstadoPago.COMPLETADO)).one()
        rechazados = self.session.exec(select(func.count(Pago.id)).where(Pago.estado_pago == EstadoPago.RECHAZADO)).one()
        
        monto_total = self.session.exec(select(func.sum(Pago.monto))).one() or 0.0
        monto_pendiente = self.session.exec(select(func.sum(Pago.monto)).where(Pago.estado_pago == EstadoPago.PENDIENTE)).one() or 0.0
        monto_completado = self.session.exec(select(func.sum(Pago.monto)).where(Pago.estado_pago == EstadoPago.COMPLETADO)).one() or 0.0
        
        return {
            "total": total,
            "pendientes": pendientes,
            "completados": completados,
            "rechazados": rechazados,
            "monto_total": monto_total,
            "monto_pendiente": monto_pendiente,
            "monto_completado": monto_completado
        }