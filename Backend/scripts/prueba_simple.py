# scripts/prueba_simple.py
import requests
import os
from dotenv import load_dotenv

load_dotenv()

def prueba_crear_pago():
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    pago_data = {
        "cliente_dni": "12345678",
        "monto": 100.0,
        "concepto": "Pago de prueba simple",
        "cliente_nombre": "Test User",
        "cliente_email": "test@test.com"
    }
    
    try:
        print("📤 Enviando pago de prueba...")
        response = requests.post(
            f"{backend}/api/mercado-pago/crear-pago-prueba",
            json=pago_data,
            timeout=30
        )
        
        print(f"📥 Respuesta: {response.status_code}")
        print(f"📄 Contenido: {response.text}")
        
        if response.status_code == 200:
            print("✅ ¡Éxito!")
            return response.json()
        else:
            print("❌ Error en la respuesta")
            
    except Exception as e:
        print(f"💥 Error: {e}")

if __name__ == "__main__":
    prueba_crear_pago()