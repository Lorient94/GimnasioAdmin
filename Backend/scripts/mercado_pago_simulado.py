# servicios/mercado_pago_simulado.py
import uuid
from typing import Dict, Any
from datetime import datetime

class MercadoPagoSimulado:
    """Servicio simulado de Mercado Pago para desarrollo - FUNCIONA SIN TOKEN"""
    
    def __init__(self):
        print("🎭 MODO SIMULACIÓN ACTIVADO - Mercado Pago Simulado")
        print("   ✅ Puedes desarrollar sin token real")
        print("   ✅ Los pagos se guardan en tu base de datos")
        print("   ✅ URLs de pago simuladas para testing")
    
    def crear_preferencia_pago(self, pago_data: Dict[str, Any]) -> Dict[str, Any]:
        """Simular creación de preferencia - SIN CONEXIÓN A MP"""
        print(f"🎭 SIMULANDO: Creando preferencia para '{pago_data['concepto']}' - ${pago_data['monto']}")
        
        # Generar IDs simulados
        preference_id = f"SIM-{uuid.uuid4().hex[:8].upper()}"
        referencia = f"TEST-{uuid.uuid4().hex[:6].upper()}"
        
        # URL de prueba simulada
        init_point = "https://www.mercadopago.com.ar/checkout/v1/redirect?pref_id=TEST-SIMULADO"
        sandbox_point = f"http://localhost:3000/pago-simulado?pref_id={preference_id}&monto={pago_data['monto']}"
        
        print(f"   🔑 Preference ID simulado: {preference_id}")
        print(f"   📋 Referencia: {referencia}")
        print(f"   🌐 URL Simulada: {sandbox_point}")
        
        return {
            "success": True,
            "preference_id": preference_id,
            "init_point": init_point,
            "sandbox_init_point": sandbox_point,
            "referencia_interna": referencia,
            "modo": "simulado",
            "mensaje": "✅ Pago simulado - Modo desarrollo activado",
            "instrucciones": "Usa el modo simulado para desarrollar sin conexión a Mercado Pago real"
        }
    
    def verificar_pago(self, payment_id: str) -> Dict[str, Any]:
        """Simular verificación de pago"""
        return {
            "status": "approved",
            "status_detail": "accredited", 
            "id": payment_id,
            "date_approved": datetime.now().isoformat(),
            "modo": "simulado",
            "mensaje": "Pago verificado en modo simulado"
        }
    
    def simular_pago_exitoso(self, preference_id: str) -> Dict[str, Any]:
        """Simular un pago exitoso"""
        return {
            "success": True,
            "payment_id": f"SIM-PAY-{uuid.uuid4().hex[:8]}",
            "status": "approved",
            "preference_id": preference_id,
            "modo": "simulado"
        }