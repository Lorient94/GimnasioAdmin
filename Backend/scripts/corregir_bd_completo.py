# scripts/corregir_bd_completo.py
import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

def corregir_tabla_pago():
    """Corregir completamente la tabla pago"""
    print("🔧 Corrigiendo estructura de la tabla pago...")
    
    try:
        connection = pymysql.connect(
            host='localhost',
            port=3308,
            user='root',
            password='123456',
            database='gimnasio'
        )
        
        with connection.cursor() as cursor:
            # Verificar y agregar columnas faltantes
            columnas_necesarias = [
                "preference_id VARCHAR(255)",
                "activo BOOLEAN DEFAULT TRUE", 
                "fecha_eliminacion DATETIME NULL",
                "motivo_eliminacion VARCHAR(255) NULL",
                "eliminado_por VARCHAR(255) NULL"
            ]
            
            for columna in columnas_necesarias:
                nombre_columna = columna.split(' ')[0]
                
                # Verificar si existe
                cursor.execute("""
                    SELECT COLUMN_NAME 
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_SCHEMA = 'gimnasio' 
                    AND TABLE_NAME = 'pago' 
                    AND COLUMN_NAME = %s
                """, (nombre_columna,))
                
                if not cursor.fetchone():
                    print(f"🔄 Agregando columna: {nombre_columna}")
                    cursor.execute(f"ALTER TABLE pago ADD COLUMN {columna}")
                else:
                    print(f"✅ Columna {nombre_columna} ya existe")
            
            connection.commit()
            print("🎉 Estructura de la tabla pago corregida completamente")
        
        connection.close()
        return True
        
    except Exception as e:
        print(f"❌ Error corrigiendo BD: {e}")
        return False

def verificar_estado_bd():
    """Verificar el estado completo de la BD"""
    print("\n📊 Estado de la base de datos:")
    
    try:
        connection = pymysql.connect(
            host='localhost',
            port=3308,
            user='root',
            password='123456',
            database='gimnasio'
        )
        
        with connection.cursor() as cursor:
            # Contar registros
            cursor.execute("SELECT COUNT(*) FROM pago")
            total_pagos = cursor.fetchone()[0]
            print(f"   Total de pagos: {total_pagos}")
            
            # Verificar estructura
            cursor.execute("DESCRIBE pago")
            columnas = [col[0] for col in cursor.fetchall()]
            print(f"   Columnas en pago: {len(columnas)}")
            print(f"   Columnas: {', '.join(columnas)}")
        
        connection.close()
        
    except Exception as e:
        print(f"❌ Error verificando BD: {e}")

if __name__ == "__main__":
    print("🚀 CORRECCIÓN COMPLETA DE BASE DE DATOS")
    print("=" * 50)
    
    if corregir_tabla_pago():
        verificar_estado_bd()
        print("\n✅ Base de datos lista para usar")
    else:
        print("\n❌ Error corrigiendo la base de datos")