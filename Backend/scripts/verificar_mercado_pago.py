# scripts/verificar_mercado_pago.py
import os
import sys
import requests
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

def verificar_configuracion():
    print("🔍 Verificando configuración de Mercado Pago...")
    
    # Verificar variables de entorno
    mp_token = os.getenv('MERCADOPAGO_ACCESS_TOKEN')
    backend_url = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    print(f"✅ MERCADOPAGO_ACCESS_TOKEN: {'✅ Configurado' if mp_token else '❌ No configurado'}")
    print(f"✅ BACKEND_URL: {backend_url}")
    
    if not mp_token:
        print("❌ ERROR: MERCADOPAGO_ACCESS_TOKEN no está configurado")
        return False
    
    # Verificar que el token es de prueba
    if not mp_token.startswith('TEST-'):
        print("⚠️  ADVERTENCIA: El token no parece ser de prueba (no comienza con TEST-)")
    
    return True

def verificar_endpoints():
    backend_url = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    endpoints = [
        "/health",
        "/api/mercado-pago/admin/pagos",
        "/api/mercado-pago/tarjetas-prueba"
    ]
    
    print(f"\n🔍 Verificando endpoints en {backend_url}...")
    
    for endpoint in endpoints:
        try:
            response = requests.get(f"{backend_url}{endpoint}", timeout=10)
            status = "✅" if response.status_code == 200 else "❌"
            print(f"{status} {endpoint}: {response.status_code}")
        except Exception as e:
            print(f"❌ {endpoint}: Error - {e}")

def probar_crear_pago_prueba():
    backend_url = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    print(f"\n🧪 Probando creación de pago de prueba...")
    
    pago_data = {
        "cliente_dni": "12345678",
        "monto": 100.0,
        "concepto": "Pago de prueba",
        "cliente_nombre": "Usuario Prueba",
        "cliente_email": "test@test.com"
    }
    
    try:
        response = requests.post(
            f"{backend_url}/api/mercado-pago/crear-pago-prueba",
            json=pago_data,
            timeout=10
        )
        
        if response.status_code == 200:
            resultado = response.json()
            print("✅ Pago de prueba creado exitosamente!")
            print(f"   Preference ID: {resultado.get('preference_id')}")
            print(f"   URL de pago: {resultado.get('init_point')}")
            return resultado.get('preference_id')
        else:
            print(f"❌ Error creando pago: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error en pago prueba: {e}")
        return None

if __name__ == "__main__":
    print("🚀 INICIANDO VERIFICACIÓN DE MERCADO PAGO")
    print("=" * 50)
    
    if verificar_configuracion():
        verificar_endpoints()
        preference_id = probar_crear_pago_prueba()
        
        if preference_id:
            print(f"\n🎯 Para probar manualmente:")
            print(f"1. Ve a: https://www.mercadopago.com.ar/developers/es/docs/checkout-pro/integration-test/test-cards")
            print(f"2. Usa las tarjetas de prueba")
            print(f"3. O usa el endpoint: POST /api/mercado-pago/simular-pago-exitoso/{preference_id}")
        
    print("\n" + "=" * 50)
    print("✅ Verificación completada")