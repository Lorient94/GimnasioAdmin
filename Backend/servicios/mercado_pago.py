# servicios/mercado_pago_service.py
import mercadopago
import os
from typing import Dict, Any, Optional
from datetime import datetime
import uuid

class MercadoPagoService:
    def __init__(self):
        # Configurar con tus credenciales de Mercado Pago
        self.access_token = os.getenv('MERCADOPAGO_ACCESS_TOKEN', 'TEST-YOUR-ACCESS-TOKEN')
        self.sdk = mercadopago.SDK(self.access_token)
    
    def crear_preferencia_pago(self, pago_data: Dict[str, Any]) -> Dict[str, Any]:
        """Crear una preferencia de pago en Mercado Pago"""
        try:
            # Generar ID único para la referencia
            referencia_interna = f"MP-{uuid.uuid4().hex[:8].upper()}"
            
            preference_data = {
                "items": [
                    {
                        "title": pago_data["concepto"],
                        "quantity": 1,
                        "currency_id": "ARS",
                        "unit_price": float(pago_data["monto"])
                    }
                ],
                "payer": {
                    "email": f"{pago_data['cliente_dni']}@temp.com",  # Email temporal
                    "identification": {
                        "type": "DNI",
                        "number": pago_data["cliente_dni"]
                    }
                },
                "payment_methods": {
                    "excluded_payment_types": [
                        {"id": "atm"}  # Excluir cajeros automáticos
                    ],
                    "installments": 1  # Una sola cuota
                },
                "back_urls": {
                    "success": f"{os.getenv('FRONTEND_URL')}/pago/exitoso",
                    "failure": f"{os.getenv('FRONTEND_URL')}/pago/fallido", 
                    "pending": f"{os.getenv('FRONTEND_URL')}/pago/pendiente"
                },
                "auto_return": "approved",
                "external_reference": referencia_interna,
                "notification_url": f"{os.getenv('BACKEND_URL')}/api/mercado-pago/webhook",
                "statement_descriptor": "GYM-CLASSES"
            }
            
            # Crear preferencia
            preference_result = self.sdk.preference().create(preference_data)
            
            if preference_result["status"] in [200, 201]:
                return {
                    "preference_id": preference_result["response"]["id"],
                    "init_point": preference_result["response"]["init_point"],
                    "sandbox_init_point": preference_result["response"]["sandbox_init_point"],
                    "referencia_interna": referencia_interna
                }
            else:
                return {"error": "Error al crear preferencia en Mercado Pago"}
                
        except Exception as e:
            return {"error": f"Error en Mercado Pago: {str(e)}"}
    
    def verificar_pago(self, payment_id: str) -> Dict[str, Any]:
        """Verificar el estado de un pago en Mercado Pago"""
        try:
            payment_result = self.sdk.payment().get(payment_id)
            
            if payment_result["status"] == 200:
                payment = payment_result["response"]
                return {
                    "id": payment["id"],
                    "status": payment["status"],
                    "status_detail": payment["status_detail"],
                    "external_reference": payment.get("external_reference", ""),
                    "amount": payment["transaction_amount"],
                    "currency": payment["currency_id"],
                    "date_created": payment["date_created"],
                    "date_approved": payment.get("date_approved"),
                    "payment_method": payment["payment_method_id"],
                    "payer": payment["payer"]
                }
            else:
                return {"error": "No se pudo obtener información del pago"}
                
        except Exception as e:
            return {"error": f"Error al verificar pago: {str(e)}"}
    
    def procesar_webhook(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Procesar notificación webhook de Mercado Pago"""
        try:
            if data.get("type") == "payment":
                payment_id = data["data"]["id"]
                payment_info = self.verificar_pago(payment_id)
                
                if "error" not in payment_info:
                    return {
                        "processed": True,
                        "payment_id": payment_id,
                        "status": payment_info["status"],
                        "external_reference": payment_info["external_reference"]
                    }
            
            return {"processed": False, "reason": "Tipo de notificación no soportado"}
            
        except Exception as e:
            return {"error": f"Error procesando webhook: {str(e)}"}
    
    def reembolsar_pago(self, payment_id: str, amount: float = None) -> Dict[str, Any]:
        """Realizar reembolso de un pago"""
        try:
            refund_data = {}
            if amount:
                refund_data["amount"] = float(amount)
            
            refund_result = self.sdk.refund().create(payment_id, refund_data)
            
            if refund_result["status"] in [200, 201]:
                return {
                    "refund_id": refund_result["response"]["id"],
                    "status": refund_result["response"]["status"],
                    "amount": refund_result["response"].get("amount")
                }
            else:
                return {"error": "Error al procesar reembolso"}
                
        except Exception as e:
            return {"error": f"Error en reembolso: {str(e)}"}