# scripts/migrar_simple.py - VERSIÓN MUY SIMPLE
import pymysql
from datetime import datetime

def migrar_pagos_simple():
    """Migración simple usando SQL directo"""
    
    # Conectar a la base de datos
    connection = pymysql.connect(
        host='localhost',
        port=3308,
        user='root',
        password='123456',
        database='gimnasio'
    )
    
    try:
        with connection.cursor() as cursor:
            # 1. Contar pagos sin transacción
            cursor.execute("SELECT COUNT(*) FROM pago WHERE transaccion_id IS NULL")
            total_pagos = cursor.fetchone()[0]
            print(f"🔍 Encontrados {total_pagos} pagos sin transacción")
            
            if total_pagos == 0:
                print("✅ No hay pagos para migrar")
                return
            
            # 2. Obtener pagos sin transacción
            cursor.execute("""
                SELECT id, id_usuario, monto, concepto, estado_pago, referencia, 
                       fecha_creacion, fecha_actualizacion 
                FROM pago 
                WHERE transaccion_id IS NULL
            """)
            pagos = cursor.fetchall()
            
            # 3. Crear transacciones para cada pago
            for pago in pagos:
                pago_id, usuario, monto, concepto, estado_pago, referencia, fecha_creacion, fecha_actualizacion = pago
                
                print(f"🔄 Migrando pago ID: {pago_id}, Usuario: {usuario}")
                
                # Mapear estado
                estado_map = {
                    'pendiente': 'pendiente',
                    'completado': 'completada', 
                    'rechazado': 'rechazada',
                    'cancelado': 'cancelada',
                    'reembolsado': 'reembolsada'
                }
                estado_transaccion = estado_map.get(estado_pago, 'pendiente')
                
                # Crear transacción
                referencia_transaccion = f"MIG-{referencia if referencia else pago_id}"
                cursor.execute("""
                    INSERT INTO transaccion 
                    (cliente_dni, monto, concepto, metodo_pago, estado, referencia, fecha, fecha_actualizacion)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    usuario, monto, concepto or f"Pago migrado #{pago_id}", 
                    'mercado_pago', estado_transaccion, referencia_transaccion,
                    fecha_creacion, fecha_actualizacion
                ))
                
                transaccion_id = cursor.lastrowid
                
                # Asociar pago con transacción
                cursor.execute("""
                    UPDATE pago SET transaccion_id = %s WHERE id = %s
                """, (transaccion_id, pago_id))
                
                print(f"✅ Pago {pago_id} asociado a transacción {transaccion_id}")
            
            # Confirmar cambios
            connection.commit()
            print("🎉 Migración completada!")
            
    finally:
        connection.close()

if __name__ == "__main__":
    migrar_pagos_simple()