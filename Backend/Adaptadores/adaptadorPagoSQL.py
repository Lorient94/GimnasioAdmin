# Adaptadores/adaptadorPagoSQL.py
from models.pago import Pago, EstadoPago
from sqlmodel import Session, select, func
from typing import List, Optional, Dict, Any
from datetime import datetime

class AdaptadorPagoSQL:
    def __init__(self, session: Session):
        self.session = session

    # ✅ MÉTODO MEJORADO: Soft delete en lugar de eliminación permanente
    def eliminar_pago(self, pago_id: int, motivo: str = "Eliminado por administrador", eliminado_por: str = "sistema") -> bool:
        """Soft delete: marcar pago como inactivo en lugar de eliminarlo"""
        pago = self.session.get(Pago, pago_id)
        if not pago or not pago.activo:
            return False
        
        # No permitir eliminar pagos completados (política de negocio)
        if pago.estado_pago == EstadoPago.COMPLETADO:
            raise ValueError("No se puede eliminar un pago completado por políticas de auditoría")
        
        pago.activo = False
        pago.fecha_eliminacion = datetime.utcnow()
        pago.motivo_eliminacion = motivo
        pago.eliminado_por = eliminado_por
        pago.fecha_actualizacion = datetime.utcnow()
        
        self.session.add(pago)
        self.session.commit()
        return True

    # ✅ MÉTODO NUEVO: Restaurar pago eliminado
    def restaurar_pago(self, pago_id: int) -> bool:
        """Restaurar un pago que fue marcado como eliminado"""
        pago = self.session.get(Pago, pago_id)
        if not pago or pago.activo:
            return False
        
        pago.activo = True
        pago.fecha_eliminacion = None
        pago.motivo_eliminacion = None
        pago.eliminado_por = None
        pago.fecha_actualizacion = datetime.utcnow()
        
        self.session.add(pago)
        self.session.commit()
        return True

    # ✅ MÉTODO NUEVO: Eliminación permanente (solo para admin avanzado)
    def eliminar_pago_permanentemente(self, pago_id: int) -> bool:
        """Eliminación permanente - USAR CON PRECAUCIÓN"""
        pago = self.session.get(Pago, pago_id)
        if not pago:
            return False
        
        # Solo permitir eliminación permanente de pagos que ya están marcados como eliminados
        if pago.activo:
            raise ValueError("No se puede eliminar permanentemente un pago activo. Use soft delete primero.")
        
        self.session.delete(pago)
        self.session.commit()
        return True

    # ✅ ACTUALIZAR: Todos los métodos de consulta para filtrar por activo=True
    def consultar_pago(self, pago_id: int) -> Optional[Pago]:
        statement = select(Pago).where(
            (Pago.id == pago_id) & 
            (Pago.activo == True)  # ✅ Solo pagos activos
        )
        return self.session.exec(statement).first()

    def listar_pagos(self, 
                   estado_pago: Optional[EstadoPago] = None,
                   id_usuario: Optional[str] = None,
                   transaccion_id: Optional[int] = None,
                   incluir_eliminados: bool = False) -> List[Pago]:  # ✅ Nuevo parámetro
        query = select(Pago)
        
        # ✅ Filtrar por activo a menos que se soliciten eliminados
        if not incluir_eliminados:
            query = query.where(Pago.activo == True)
        
        if estado_pago:
            query = query.where(Pago.estado_pago == estado_pago)
        
        if id_usuario:
            query = query.where(Pago.id_usuario == id_usuario)
        
        if transaccion_id:
            query = query.where(Pago.transaccion_id == transaccion_id)
        
        query = query.order_by(Pago.fecha_creacion.desc())
        
        return list(self.session.exec(query))

    # ✅ MÉTODO NUEVO: Obtener pagos eliminados
    def listar_pagos_eliminados(self) -> List[Pago]:
        """Obtener todos los pagos marcados como eliminados"""
        statement = select(Pago).where(Pago.activo == False).order_by(Pago.fecha_eliminacion.desc())
        return list(self.session.exec(statement))

    # ✅ MÉTODO NUEVO: Estadísticas incluyendo eliminados
    def obtener_estadisticas_completas(self) -> Dict[str, Any]:
        """Estadísticas que incluyen información sobre pagos eliminados"""
        todos_los_pagos = self.session.exec(select(Pago)).all()
        pagos_activos = [p for p in todos_los_pagos if p.activo]
        pagos_eliminados = [p for p in todos_los_pagos if not p.activo]
        
        return {
            "total_registros": len(todos_los_pagos),
            "activos": len(pagos_activos),
            "eliminados": len(pagos_eliminados),
            "porcentaje_eliminados": f"{(len(pagos_eliminados) / len(todos_los_pagos) * 100):.1f}%" if todos_los_pagos else "0%",
            "estadisticas_activos": self._calcular_estadisticas(pagos_activos),
            "estadisticas_eliminados": self._calcular_estadisticas(pagos_eliminados)
        }
    
    def _calcular_estadisticas(self, pagos: List[Pago]) -> Dict[str, Any]:
        return {
            "total": len(pagos),
            "pendientes": len([p for p in pagos if p.estado_pago == EstadoPago.PENDIENTE]),
            "completados": len([p for p in pagos if p.estado_pago == EstadoPago.COMPLETADO]),
            "rechazados": len([p for p in pagos if p.estado_pago == EstadoPago.RECHAZADO]),
            "monto_total": sum(p.monto for p in pagos)
        }