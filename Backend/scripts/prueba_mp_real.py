# scripts/prueba_mp_real.py
import requests
import os
from dotenv import load_dotenv

load_dotenv()

def probar_pago_mercadopago():
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    print("🧪 PROBANDO PAGO CON MERCADO PAGO REAL...")
    
    pago_data = {
        "cliente_dni": "12345678",
        "monto": 100.0,
        "concepto": "Mensualidad Gimnasio - Prueba Real",
        "cliente_nombre": "Juan Pérez",
        "cliente_email": "juan.perez@test.com"
    }
    
    try:
        print("📤 Enviando pago a Mercado Pago...")
        response = requests.post(
            f"{backend}/api/mercado-pago/crear-pago-prueba",
            json=pago_data,
            timeout=30
        )
        
        print(f"📥 Status: {response.status_code}")
        
        if response.status_code == 200:
            resultado = response.json()
            print("🎉 ¡ÉXITO! Pago creado correctamente")
            print(f"🔑 Pago ID: {resultado.get('pago_id')}")
            print(f"📋 Preference ID: {resultado.get('preference_id')}")
            print(f"🌐 URL de pago: {resultado.get('init_point')}")
            
            # Guardar el preference_id para pruebas posteriores
            if resultado.get('preference_id'):
                with open('preference_id.txt', 'w') as f:
                    f.write(resultado['preference_id'])
                print("💾 Preference ID guardado en preference_id.txt")
                
        else:
            print(f"❌ Error: {response.text}")
            
    except Exception as e:
        print(f"💥 Error: {e}")

def probar_simulacion_pago():
    """Probar la simulación de pago exitoso si tenemos un preference_id"""
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    # Intentar cargar preference_id guardado
    try:
        with open('preference_id.txt', 'r') as f:
            preference_id = f.read().strip()
    except:
        print("📝 No hay preference_id guardado para simular")
        return
    
    if preference_id:
        print(f"\n🎯 Simulando pago exitoso para: {preference_id}")
        
        try:
            response = requests.post(
                f"{backend}/api/mercado-pago/simular-pago-exitoso/{preference_id}",
                timeout=15
            )
            
            print(f"📥 Status: {response.status_code}")
            if response.status_code == 200:
                print("✅ Pago simulado exitosamente!")
                print(f"📄 Resultado: {response.json()}")
            else:
                print(f"❌ Error en simulación: {response.text}")
                
        except Exception as e:
            print(f"💥 Error en simulación: {e}")

def verificar_pagos_existentes():
    """Verificar pagos existentes en la base de datos"""
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    print("\n📊 Verificando pagos existentes...")
    
    try:
        response = requests.get(f"{backend}/api/mercado-pago/pagos", timeout=10)
        
        if response.status_code == 200:
            pagos = response.json()
            print(f"✅ Se encontraron {len(pagos)} pagos")
            
            for pago in pagos[:3]:  # Mostrar solo los primeros 3
                print(f"   - ID: {pago.get('id')}, Estado: {pago.get('estado_pago')}, Monto: ${pago.get('monto')}")
        else:
            print(f"❌ Error obteniendo pagos: {response.text}")
            
    except Exception as e:
        print(f"💥 Error: {e}")

if __name__ == "__main__":
    probar_pago_mercadopago()
    probar_simulacion_pago()
    verificar_pagos_existentes()