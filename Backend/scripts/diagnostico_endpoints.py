# scripts/diagnostico_endpoints.py
import requests
import os
from dotenv import load_dotenv

load_dotenv()

def descubrir_endpoints():
    backend_url = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    print("🔍 Descubriendo endpoints disponibles...")
    
    # Endpoints posibles
    endpoints_posibles = [
        "/api/mercado-pago/pagos",
        "/api/mercado-pago/admin/pagos", 
        "/api/mercado-pago/crear-pago",
        "/api/mercado-pago/crear-preferencia",
        "/api/mercado-pago/crear-pago-prueba",
        "/api/mercado-pago/tarjetas-prueba",
        "/api/mercado-pago/simular-pago-exitoso/123",
        "/admin/pagos",
        "/pagos"
    ]
    
    for endpoint in endpoints_posibles:
        try:
            response = requests.get(f"{backend_url}{endpoint}", timeout=5)
            metodo = "GET"
        except:
            try:
                response = requests.post(f"{backend_url}{endpoint}", timeout=5, json={})
                metodo = "POST"
            except Exception as e:
                print(f"❌ {endpoint}: No responde - {e}")
                continue
        
        if response.status_code != 404:
            print(f"✅ {metodo} {endpoint}: {response.status_code}")

if __name__ == "__main__":
    descubrir_endpoints()