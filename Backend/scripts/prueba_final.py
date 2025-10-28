# scripts/prueba_final.py
import requests
import os
from dotenv import load_dotenv

load_dotenv()

def probar_todos_los_endpoints():
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    endpoints = [
        ("GET", "/api/mercado-pago/test"),
        ("GET", "/api/mercado-pago/pagos"),
        ("GET", "/api/mercado-pago/tarjetas-prueba"),
    ]
    
    print("🔍 Probando endpoints de Mercado Pago...")
    for metodo, endpoint in endpoints:
        try:
            if metodo == "GET":
                response = requests.get(f"{backend}{endpoint}", timeout=10)
            else:
                response = requests.post(f"{backend}{endpoint}", timeout=10, json={})
            
            status = "✅" if response.status_code == 200 else "❌"
            print(f"{status} {metodo} {endpoint}: {response.status_code}")
            
            if response.status_code != 200:
                print(f"   Contenido: {response.text}")
                
        except Exception as e:
            print(f"❌ {metodo} {endpoint}: Error - {e}")

def probar_crear_pago():
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    pago_data = {
        "cliente_dni": "12345678",
        "monto": 100.0,
        "concepto": "Pago Test Simple",
        "cliente_nombre": "Test User",
        "cliente_email": "test@test.com"
    }
    
    print("\n🧪 Probando crear pago...")
    try:
        response = requests.post(
            f"{backend}/api/mercado-pago/crear-pago-prueba",
            json=pago_data,
            timeout=30
        )
        
        print(f"📥 Status: {response.status_code}")
        print(f"📄 Response: {response.text}")
        
    except Exception as e:
        print(f"💥 Error: {e}")

if __name__ == "__main__":
    probar_todos_los_endpoints()
    probar_crear_pago()