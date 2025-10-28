# scripts/test_directo.py
import requests
import os
from dotenv import load_dotenv

load_dotenv()

def test_directo():
    backend = "http://localhost:8000"
    
    print("🎯 TEST DIRECTO - Endpoint por endpoint")
    
    # 1. Test diagnóstico
    print("\n1. Probando diagnóstico...")
    try:
        r = requests.get(f"{backend}/api/mercado-pago/diagnostico")
        print(f"   Status: {r.status_code}")
        if r.status_code == 200:
            print("   ✅ Diagnóstico OK")
            print(f"   BD Pagos: {r.json().get('database', {}).get('total_pagos', 0)}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # 2. Test MP directo
    print("\n2. Probando Mercado Pago directo...")
    try:
        r = requests.post(f"{backend}/api/mercado-pago/test-mp")
        print(f"   Status: {r.status_code}")
        if r.status_code == 200:
            resultado = r.json()
            if 'error' in resultado.get('test_mercado_pago', {}):
                print(f"   ❌ Error MP: {resultado['test_mercado_pago']['error']}")
            else:
                print("   ✅ Mercado Pago funcionando!")
        else:
            print(f"   ❌ Error: {r.text}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # 3. Test crear pago simple
    print("\n3. Probando crear pago simple...")
    try:
        pago_data = {
            "cliente_dni": "12345678",
            "monto": 1.0,  # Monto mínimo
            "concepto": "Test Mínimo",
            "cliente_nombre": "Test",
            "cliente_email": "test@test.com"
        }
        
        r = requests.post(f"{backend}/api/mercado-pago/crear-pago-prueba", json=pago_data)
        print(f"   Status: {r.status_code}")
        if r.status_code == 200:
            print("   ✅ Pago creado exitosamente!")
            resultado = r.json()
            print(f"   Pago ID: {resultado.get('pago_id')}")
            print(f"   URL: {resultado.get('init_point')}")
        else:
            print(f"   ❌ Error: {r.text}")
    except Exception as e:
        print(f"   ❌ Error: {e}")

if __name__ == "__main__":
    test_directo()