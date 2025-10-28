# scripts/verificar_token_mp.py
import os
import requests
from dotenv import load_dotenv

load_dotenv()

def verificar_token_actual():
    """Verificar si el token actual funciona"""
    token = os.getenv('MERCADOPAGO_ACCESS_TOKEN')
    
    print("🔍 Verificando token actual...")
    print(f"Token: {token}")
    
    if not token:
        print("❌ No hay token configurado")
        return False
    
    # Hacer una prueba directa con la API de Mercado Pago
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    try:
        # Intentar crear una preferencia de prueba
        test_data = {
            "items": [{
                "title": "Test",
                "quantity": 1,
                "currency_id": "ARS",
                "unit_price": 10.0
            }]
        }
        
        response = requests.post(
            "https://api.mercadopago.com/checkout/preferences",
            headers=headers,
            json=test_data,
            timeout=10
        )
        
        print(f"📊 Respuesta de MP: {response.status_code}")
        
        if response.status_code == 201:
            print("✅ Token VÁLIDO - Puede crear preferencias")
            return True
        else:
            print(f"❌ Token INVÁLIDO - Error {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"💥 Error de conexión: {e}")
        return False

def mostrar_instrucciones_token():
    """Mostrar instrucciones detalladas para obtener token"""
    print("\n🎯 INSTRUCCIONES DETALLADAS:")
    print("1. Ve a: https://www.mercadopago.com.ar/developers/panel")
    print("2. Inicia sesión con tu cuenta de Mercado Pago")
    print("3. Si no tienes una aplicación, crea una nueva:")
    print("   - Haz clic en 'Crear aplicación'")
    print("   - Nombre: 'Gimnasio App'")
    print("   - Categoría: 'E-commerce'")
    print("   - Sitio web: http://localhost:3000")
    print("4. En la sección 'Credenciales' copia el 'Access Token'")
    print("5. El token debe empezar con 'TEST-' y ser largo")
    print("\n📝 Ejemplo de formato correcto:")
    print("TEST-1234567890123456-012345-abcdef1234567890abcdef1234567890")

def generar_token_prueba_alternativo():
    """Generar instrucciones para testing alternativo"""
    print("\n🔄 ALTERNATIVA: Usar modo desarrollo sin Mercado Pago real")
    print("Puedes simular pagos sin conexión a Mercado Pago:")
    print("1. Modificar el servicio para modo prueba")
    print("2. Usar datos de prueba locales")
    print("3. Simular respuestas de Mercado Pago")

if __name__ == "__main__":
    print("🚀 VERIFICACIÓN COMPLETA DE TOKEN MERCADO PAGO")
    print("=" * 60)
    
    token_valido = verificar_token_actual()
    
    if not token_valido:
        mostrar_instrucciones_token()
        generar_token_prueba_alternativo()