import pymysql
from datetime import datetime
import sys
import os

def migrar_pagos_simple():
    """Migración simple usando SQL directo - VERSIÓN CORREGIDA"""
    
    print("🚀 Iniciando migración de pagos sin transacción...")
    
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
            cursor.execute("SELECT COUNT(*) FROM pago WHERE transaccion_id IS NULL AND activo = TRUE")
            total_pagos = cursor.fetchone()[0]
            print(f"🔍 Encontrados {total_pagos} pagos sin transacción")
            
            if total_pagos == 0:
                print("✅ No hay pagos para migrar")
                return
            
            # 2. Obtener pagos sin transacción
            cursor.execute("""
                SELECT id, id_usuario, monto, concepto, estado_pago, referencia, 
                       fecha_creacion, fecha_actualizacion, metodo_pago
                FROM pago 
                WHERE transaccion_id IS NULL AND activo = TRUE
            """)
            pagos = cursor.fetchall()
            
            # 3. Crear transacciones para cada pago
            for pago in pagos:
                pago_id, usuario, monto, concepto, estado_pago, referencia, fecha_creacion, fecha_actualizacion, metodo_pago = pago
                
                print(f"🔄 Migrando pago ID: {pago_id}, Usuario: {usuario}, Estado: {estado_pago}")
                
                # Mapear estado de pago a estado de transacción
                estado_map = {
                    'pendiente': 'pendiente',
                    'completado': 'completada', 
                    'rechazado': 'rechazada',
                    'cancelado': 'cancelada',
                    'reembolsado': 'reembolsada'
                }
                estado_transaccion = estado_map.get(estado_pago, 'pendiente')
                
                # Mapear método de pago
                metodo_pago_map = {
                    'mercado_pago': 'mercado_pago',
                    'efectivo': 'efectivo',
                    'tarjeta': 'tarjeta de crédito'  # Ajusta según tus necesidades
                }
                metodo_transaccion = metodo_pago_map.get(metodo_pago, 'mercado_pago')
                
                # Crear concepto si no existe
                concepto_transaccion = concepto or f"Pago migrado #{pago_id}"
                referencia_transaccion = f"MIG-{referencia if referencia else pago_id}"
                
                # Verificar si el cliente existe
                cursor.execute("SELECT dni FROM cliente WHERE dni = %s", (usuario,))
                cliente_existe = cursor.fetchone()
                
                if not cliente_existe:
                    print(f"⚠️  Cliente {usuario} no existe, saltando pago {pago_id}")
                    continue
                
                # Crear transacción
                cursor.execute("""
                    INSERT INTO transaccion 
                    (cliente_dni, monto, concepto, metodo_pago, estado, referencia, fecha, fecha_actualizacion)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    usuario, 
                    monto, 
                    concepto_transaccion, 
                    metodo_transaccion, 
                    estado_transaccion, 
                    referencia_transaccion,
                    fecha_creacion, 
                    fecha_actualizacion
                ))
                
                transaccion_id = cursor.lastrowid
                
                # Asociar pago con transacción
                cursor.execute("""
                    UPDATE pago SET transaccion_id = %s WHERE id = %s
                """, (transaccion_id, pago_id))
                
                print(f"✅ Pago {pago_id} asociado a transacción {transaccion_id} (Estado: {estado_transaccion})")
            
            # Confirmar cambios
            connection.commit()
            print(f"🎉 Migración completada! {len(pagos)} pagos migrados exitosamente.")
            
    except Exception as e:
        print(f"❌ Error durante la migración: {e}")
        connection.rollback()
    finally:
        connection.close()

if __name__ == "__main__":
    migrar_pagos_simple()