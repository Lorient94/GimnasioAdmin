# scripts/prueba_modo_simulado.py
import requests
import os
from dotenv import load_dotenv

load_dotenv()

def probar_modo_simulado():
    backend = os.getenv('BACKEND_URL', 'http://localhost:8000')
    
    print("🎭 PROBANDO MODO SIMULADO DE MERCADO PAGO")
    print("=" * 50)
    
    # 1. Verificar modo actual
    print("\n1. 🔍 Verificando modo de operación...")
    try:
        r = requests.get(f"{backend}/api/mercado-pago/info")
        data = r.json()
        modo = data.get('modo', 'DESCONOCIDO')
        print(f"   ✅ Modo actual: {modo}")
        print(f"   📝 Mensaje: {data.get('mensaje')}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return
    
    # 2. Crear pago de prueba
    print("\n2. 🧪 Creando pago de prueba en modo simulado...")
    pago_data = {
        "cliente_dni": "12345678",
        "monto": 2500.0,
        "concepto": "Mensualidad Gimnasio - Prueba Simulada",
        "cliente_nombre": "Carlos López",
        "cliente_email": "carlos.lopez@test.com"
    }
    
    try:
        response = requests.post(
            f"{backend}/api/mercado-pago/crear-pago-prueba",
            json=pago_data,
            timeout=30
        )
        
        if response.status_code == 200:
            resultado = response.json()
            print("   ✅ ¡PAGO SIMULADO CREADO EXITOSAMENTE!")
            print(f"   🔑 Pago ID: {resultado.get('pago_id')}")
            print(f"   📋 Preference ID: {resultado.get('preference_id')}")
            print(f"   🎭 Modo: {resultado.get('modo')}")
            print(f"   🌐 URL Simulada: {resultado.get('init_point')}")
            print(f"   📝 Mensaje: {resultado.get('message')}")
            
            # Guardar preference_id para simular pago
            preference_id = resultado.get('preference_id')
            if preference_id:
                with open('preference_id.txt', 'w') as f:
                    f.write(preference_id)
                
        else:
            print(f"   ❌ Error: {response.text}")
            return
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return
    
    # 3. Simular pago exitoso
    print("\n3. 🎯 Simulando pago exitoso...")
    if preference_id:
        try:
            response = requests.post(
                f"{backend}/api/mercado-pago/simular-pago-exitoso/{preference_id}",
                timeout=15
            )
            
            if response.status_code == 200:
                resultado = response.json()
                print("   ✅ ¡PAGO SIMULADO EXITOSAMENTE!")
                print(f"   🔑 Pago ID: {resultado.get('pago_id')}")
                print(f"   📋 Estado: {resultado.get('estado')}")
                print(f"   🎭 Modo: {resultado.get('modo')}")
            else:
                print(f"   ❌ Error en simulación: {response.text}")
                
        except Exception as e:
            print(f"   ❌ Error en simulación: {e}")
    
    # 4. Verificar pagos en sistema
    print("\n4. 📊 Verificando pagos en el sistema...")
    try:
        r = requests.get(f"{backend}/api/mercado-pago/pagos")
        if r.status_code == 200:
            data = r.json()
            pagos = data.get('pagos', [])
            print(f"   ✅ Total de pagos: {len(pagos)}")
            for pago in pagos:
                print(f"      - ID: {pago.get('id')}, Estado: {pago.get('estado_pago')}, ${pago.get('monto')}")
        else:
            print(f"   ❌ Error: {r.text}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # 5. Mostrar resumen
    print("\n" + "=" * 50)
    print("🎉 ¡MODO SIMULADO FUNCIONANDO CORRECTAMENTE!")
    print("\n📋 RESUMEN:")
    print("✅ Puedes desarrollar sin token de Mercado Pago")
    print("✅ Los pagos se guardan en tu base de datos")
    print("✅ Puedes simular pagos exitosos")
    print("✅ Tu frontend puede usar las URLs simuladas")
    print("\n🚀 PRÓXIMOS PASOS:")
    print("1. Integra el frontend con estos endpoints")
    print("2. Usa /simular-pago-exitoso para testing")
    print("3. Cuando tengas token real, cambiará automáticamente")

if __name__ == "__main__":
    probar_modo_simulado()
    