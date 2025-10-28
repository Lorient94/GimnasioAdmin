# scripts/corregir_problemas.py
import os
import sys
import pymysql
from dotenv import load_dotenv

load_dotenv()

def verificar_token():
    """Verificar que el token de Mercado Pago sea válido"""
    token = os.getenv('MERCADOPAGO_ACCESS_TOKEN')
    
    print("🔍 Verificando token de Mercado Pago...")
    
    if not token:
        print("❌ ERROR: No hay token configurado")
        return False
    
    if token == "TEST-12345678901234567890123456789012":
        print("❌ ERROR: Estás usando el token de ejemplo")
        print("   Necesitas un token REAL de Mercado Pago Sandbox")
        print("   Obtén uno en: https://www.mercadopago.com.ar/developers")
        return False
    
    if not token.startswith('TEST-'):
        print("⚠️  ADVERTENCIA: El token no parece ser de Sandbox (no empieza con TEST-)")
    
    print(f"✅ Token configurado: {token[:20]}...")
    return True

def verificar_base_datos():
    """Verificar y corregir la estructura de la base de datos"""
    print("\n🔍 Verificando estructura de la base de datos...")
    
    try:
        # Conectar a la base de datos
        connection = pymysql.connect(
            host='localhost',
            port=3308,
            user='root',
            password='123456',
            database='gimnasio'
        )
        
        with connection.cursor() as cursor:
            # Verificar si existe la columna preference_id
            cursor.execute("""
                SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = 'gimnasio' 
                AND TABLE_NAME = 'pago' 
                AND COLUMN_NAME = 'preference_id'
            """)
            
            resultado = cursor.fetchone()
            
            if not resultado:
                print("❌ Columna preference_id no existe en tabla pago")
                print("🔄 Agregando columna preference_id...")
                
                cursor.execute("""
                    ALTER TABLE pago 
                    ADD COLUMN preference_id VARCHAR(255)
                """)
                connection.commit()
                print("✅ Columna preference_id agregada exitosamente")
            else:
                print("✅ Columna preference_id ya existe")
        
        connection.close()
        return True
        
    except Exception as e:
        print(f"❌ Error verificando base de datos: {e}")
        return False

def mostrar_instrucciones_token():
    """Mostrar instrucciones para obtener token real"""
    print("\n🎯 INSTRUCCIONES PARA OBTENER TOKEN REAL:")
    print("1. Ve a: https://www.mercadopago.com.ar/developers")
    print("2. Inicia sesión con tu cuenta de Mercado Pago")
    print("3. Haz clic en 'Tus aplicaciones'")
    print("4. Crea una nueva aplicación o selecciona una existente")
    print("5. Copia el 'Access Token' (debe empezar con TEST-)")
    print("6. Actualiza tu archivo .env con el token real")
    print("\n📝 Ejemplo de token real:")
    print("MERCADOPAGO_ACCESS_TOKEN=TEST-2016324737939080-121115-9a3f848d9f8f8e7f8f8f8f8f8f8f8f8f-201632473")

def main():
    print("🚀 CORRIGIENDO PROBLEMAS DE MERCADO PAGO")
    print("=" * 50)
    
    # Verificar token
    token_ok = verificar_token()
    
    # Verificar base de datos
    db_ok = verificar_base_datos()
    
    # Mostrar resumen
    print("\n" + "=" * 50)
    print("📊 RESUMEN:")
    
    if token_ok and db_ok:
        print("✅ Todos los problemas están resueltos")
        print("🎯 Ahora puedes probar los pagos nuevamente")
    else:
        if not token_ok:
            print("❌ Problema con el token de Mercado Pago")
            mostrar_instrucciones_token()
        
        if not db_ok:
            print("❌ Problema con la base de datos")

if __name__ == "__main__":
    main()