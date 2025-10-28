# servicios/mercado_pago.py - VERSIÓN QUE FALLA CLARAMENTE
import mercadopago
import os
from typing import Dict, Any
import uuid

class MercadoPagoService:
    def __init__(self):
        self.access_token = os.getenv('MERCADOPAGO_ACCESS_TOKEN')
        print(f"🔑 Token MP: {'✅' if self.access_token else '❌'} {'Configurado' if self.access_token else 'No configurado'}")
        
        if not self.access_token:
            raise ValueError("MERCADOPAGO_ACCESS_TOKEN no configurado")
            
        # ✅ FORZAR MODO SIMULADO SI EL TOKEN ES EL DE PRUEBA
        if self.access_token == "TEST-2016324737939080-121115-9a3f848d9f8f8e7f8f8f8f8f8f8f8f8f-201632473":
            print("🎭 TOKEN DE PRUEBA DETECTADO - Forzando modo simulado")
            raise ValueError("Token de prueba inválido - Activando modo simulado")
            
        try:
            self.sdk = mercadopago.SDK(self.access_token)
            print("✅ SDK de Mercado Pago inicializado")
        except Exception as e:
            print(f"❌ Error inicializando SDK: {e}")
            raise
    
    def crear_preferencia_pago(self, pago_data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            print(f"🎯 Creando preferencia para: {pago_data}")
            
            referencia = f"TEST-{uuid.uuid4().hex[:8]}"
            
            preference_data = {
                "items": [{
                    "title": pago_data["concepto"],
                    "quantity": 1,
                    "currency_id": "ARS",
                    "unit_price": float(pago_data["monto"])
                }],
                "external_reference": referencia,
                "back_urls": {
                    "success": "https://www.mercadopago.com.ar",
                    "failure": "https://www.mercadopago.com.ar", 
                    "pending": "https://www.mercadopago.com.ar"
                },
                "auto_return": "approved",
            }
            
            print("📤 Enviando a MP...")
            result = self.sdk.preference().create(preference_data)
            print(f"📥 Respuesta MP: {result.get('status')}")
            
            if result["status"] in [200, 201]:
                response_data = result["response"]
                return {
                    "success": True,
                    "preference_id": response_data["id"],
                    "init_point": response_data["init_point"],
                    "sandbox_init_point": response_data["sandbox_init_point"],
                    "referencia_interna": referencia
                }
            else:
                error_msg = f"Error MP: {result.get('response', {})}"
                print(f"❌ {error_msg}")
                return {"error": error_msg}
                
        except Exception as e:
            error_msg = f"Excepción en MP: {str(e)}"
            print(f"💥 {error_msg}")
            return {"error": error_msg}