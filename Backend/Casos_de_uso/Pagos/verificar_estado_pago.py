# Casos_de_uso/Pagos/verificar_estado_pago.py
from typing import Dict, Any
from sqlmodel import Session
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL
from servicios.mercado_pago import MercadoPagoService
from models.pago import EstadoPago

class VerificarEstadoPagoCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_pagos = AdaptadorPagoSQL(session)
        self.mercado_pago_service = MercadoPagoService()
    
    def ejecutar(self, pago_id: int) -> Dict[str, Any]:
        """Verificar el estado de un pago en Mercado Pago y actualizar localmente"""
        
        pago = self.repositorio_pagos.consultar_pago(pago_id)
        if not pago:
            return {"error": "Pago no encontrado"}
        
        if not pago.preference_id:
            return {"error": "Este pago no está asociado a Mercado Pago"}
        
        try:
            # Buscar payment_id usando la referencia
            # Nota: Necesitarías almacenar el payment_id cuando se complete el pago
            # Por ahora, asumimos que la referencia MP está en referencia_mp
            
            if not pago.referencia_mp:
                return {"error": "No hay referencia de Mercado Pago asociada"}
            
            # En un caso real, necesitarías buscar el payment_id por la referencia
            # Esto es una simplificación - en producción necesitarías un método mejor
            payment_info = self.mercado_pago_service.verificar_pago_por_referencia(pago.referencia_mp)
            
            if "error" in payment_info:
                # Intentar con el preference_id como fallback
                payment_info = self.mercado_pago_service.verificar_pago(pago.preference_id)
                if "error" in payment_info:
                    return payment_info
            
            # Mapear estado de Mercado Pago a nuestro sistema
            estado_mapeado = self._mapear_estado_mp(payment_info["status"])
            
            # Actualizar estado local si cambió
            if pago.estado_pago != estado_mapeado:
                observaciones = f"Actualizado desde Mercado Pago: {payment_info['status']} - {payment_info.get('status_detail', '')}"
                
                self.repositorio_pagos.cambiar_estado_pago(
                    pago_id, 
                    estado_mapeado,
                    observaciones
                )
                
                # Si el pago se completó, actualizar fecha de aprobación
                if estado_mapeado == EstadoPago.COMPLETADO:
                    self.repositorio_pagos.actualizar_pago(pago_id, {
                        "fecha_aprobacion": datetime.now()
                    })
            
            return {
                "success": True,
                "pago_id": pago_id,
                "estado_anterior": pago.estado_pago.value,
                "estado_actual": estado_mapeado.value,
                "detalle_mp": payment_info
            }
            
        except Exception as e:
            return {"error": f"Error al verificar pago: {str(e)}"}
    
    def _mapear_estado_mp(self, estado_mp: str) -> EstadoPago:
        mapeo = {
            "pending": EstadoPago.PENDIENTE,
            "approved": EstadoPago.COMPLETADO,
            "authorized": EstadoPago.PENDIENTE,
            "in_process": EstadoPago.PENDIENTE,
            "in_mediation": EstadoPago.PENDIENTE,
            "rejected": EstadoPago.RECHAZADO,
            "cancelled": EstadoPago.CANCELADO,
            "refunded": EstadoPago.REEMBOLSADO,
            "charged_back": EstadoPago.REEMBOLSADO
        }
        return mapeo.get(estado_mp, EstadoPago.PENDIENTE)