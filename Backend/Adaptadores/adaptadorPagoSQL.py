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

    def consultar_pago_completo(self, pago_id: int):
        """Obtener pago con información completa"""
        return self.consultar_pago(pago_id)

    def consultar_pago_por_referencia_completa(self, referencia: str):
        """Obtener pago por referencia con información completa"""
        return self.consultar_pago_por_referencia(referencia)

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

    def eliminar_pago_permanentemente(self, pago_id: int) -> bool:
        """Eliminar pago permanentemente"""
        with self.session as session:
            pago = session.get(Pago, pago_id)
            if pago:
                session.delete(pago)
                session.commit()
                return True
            return False

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

    def completar_pago_manual(self, pago_id: int, referencia_pago: str = None):
        """Completar pago manualmente"""
        with self.session as session:
            pago = session.get(Pago, pago_id)
            if pago:
                pago.estado_pago = EstadoPago.COMPLETADO
                pago.fecha_actualizacion = datetime.now()
                if referencia_pago:
                    pago.referencia_pago = referencia_pago
                session.add(pago)
                session.commit()
                session.refresh(pago)
            return pago

    def rechazar_pago_manual(self, pago_id: int, motivo: str):
        """Rechazar pago manualmente"""
        with self.session as session:
            pago = session.get(Pago, pago_id)
            if pago:
                pago.estado_pago = EstadoPago.RECHAZADO
                pago.observaciones = f"Rechazado manualmente: {motivo}"
                pago.fecha_actualizacion = datetime.now()
                session.add(pago)
                session.commit()
                session.refresh(pago)
            return pago
        
    def reembolsar_pago(self, pago_id: int, motivo: str):
        """Reembolsar un pago"""
        with self.session as session:
            pago = session.get(Pago, pago_id)
            if pago and pago.estado_pago == EstadoPago.COMPLETADO:
                pago.estado_pago = EstadoPago.REEMBOLSADO
                pago.observaciones = f"Reembolsado: {motivo}"
                pago.fecha_actualizacion = datetime.now()
                session.add(pago)
                session.commit()
                session.refresh(pago)
            return pago


    def listar_todos_los_pagos(self):
        """Listar todos los pagos"""
        with self.session as session:
            statement = select(Pago)
            return session.exec(statement).all()

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

    def obtener_estadisticas_avanzadas(self):
        """Estadísticas avanzadas de pagos"""
        pagos = self.listar_todos_los_pagos()
        
        return {
            "total": len(pagos),
            "pendientes": len([p for p in pagos if p.estado_pago == EstadoPago.PENDIENTE]),
            "completados": len([p for p in pagos if p.estado_pago == EstadoPago.COMPLETADO]),
            "rechazados": len([p for p in pagos if p.estado_pago == EstadoPago.RECHAZADO]),
            "reembolsados": len([p for p in pagos if p.estado_pago == EstadoPago.REEMBOLSADO]),
            "monto_total": sum(p.monto for p in pagos),
            "monto_pendiente": sum(p.monto for p in pagos if p.estado_pago == EstadoPago.PENDIENTE),
            "monto_completado": sum(p.monto for p in pagos if p.estado_pago == EstadoPago.COMPLETADO)
        }

    # Métodos para cumplir la interfaz RepositorioPago
    def consultar_pago(self, pago_id: int) -> Optional[Pago]:
        return self.session.get(Pago, pago_id)

    def consultar_pago_por_referencia(self, referencia: str) -> Optional[Pago]:
        statement = select(Pago).where(Pago.referencia == referencia)
        return self.session.exec(statement).first()

    def eliminar_pago(self, pago_id: int) -> bool:
        return self.eliminar_pago_permanentemente(pago_id)

    def completar_pago(self, pago_id: int) -> bool:
        pago = self.session.get(Pago, pago_id)
        if pago:
            pago.estado_pago = EstadoPago.COMPLETADO
            pago.fecha_actualizacion = datetime.utcnow()
            self.session.add(pago)
            self.session.commit()
            return True
        return False

    def rechazar_pago(self, pago_id: int) -> bool:
        pago = self.session.get(Pago, pago_id)
        if pago:
            pago.estado_pago = EstadoPago.RECHAZADO
            pago.fecha_actualizacion = datetime.utcnow()
            self.session.add(pago)
            self.session.commit()
            return True
        return False

    def obtener_estadisticas_totales(self) -> Dict[str, Any]:
        return self.obtener_estadisticas_avanzadas()