# scripts/prueba_funcional.py
import requests
import os
from dotenv import load_dotenv

load_dotenv()

def probar_endpoints_funcionales():
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    print("🧪 Probando endpoints que SÍ funcionan...")
    
    # Endpoints que sabemos que funcionan
    endpoints = [
        ("GET", "/health"),
        ("GET", "/config"), 
        ("GET", "/api/mercado-pago/test"),
        ("GET", "/api/mercado-pago/tarjetas-prueba"),
    ]
    
    for metodo, endpoint in endpoints:
        try:
            if metodo == "GET":
                response = requests.get(f"{backend}{endpoint}", timeout=10)
            else:
                response = requests.post(f"{backend}{endpoint}", timeout=10, json={})
            
            status = "✅" if response.status_code == 200 else "❌"
            print(f"{status} {metodo} {endpoint}: {response.status_code}")
            
        except Exception as e:
            print(f"❌ {metodo} {endpoint}: Error - {e}")

def probar_pago_sin_mp():
    """Probar el flujo sin Mercado Pago (solo guardar en BD)"""
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    print("\n🧪 Probando creación de pago local (sin MP)...")
    
    pago_data = {
        "id_usuario": "12345678",
        "monto": 100.0,
        "concepto": "Pago Local Test",
        "metodo_pago": "efectivo",
        "estado_pago": "completado"
    }
    
    try:
        # Usar el endpoint de transacciones que ya existe
        response = requests.post(
            f"{backend}/api/transacciones",
            json=pago_data,
            timeout=10
        )
        
        print(f"📥 Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Pago local creado exitosamente!")
            print(f"📄 Response: {response.json()}")
        else:
            print(f"📄 Error: {response.text}")
            
    except Exception as e:
        print(f"💥 Error: {e}")

if __name__ == "__main__":
    probar_endpoints_funcionales()
    probar_pago_sin_mp()