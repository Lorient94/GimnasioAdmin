import pymysql

def verificar_migracion():
    """Verificar que la migración se completó correctamente"""
    
    connection = pymysql.connect(
        host='localhost',
        port=3308,
        user='root',
        password='123456',
        database='gimnasio'
    )
    
    try:
        with connection.cursor() as cursor:
            # Pagos sin transacción
            cursor.execute("SELECT COUNT(*) FROM pago WHERE transaccion_id IS NULL AND activo = TRUE")
            pagos_sin_transaccion = cursor.fetchone()[0]
            
            # Pagos con transacción
            cursor.execute("SELECT COUNT(*) FROM pago WHERE transaccion_id IS NOT NULL AND activo = TRUE")
            pagos_con_transaccion = cursor.fetchone()[0]
            
            # Total de transacciones
            cursor.execute("SELECT COUNT(*) FROM transaccion")
            total_transacciones = cursor.fetchone()[0]
            
            print("📊 ESTADO DE LA MIGRACIÓN:")
            print(f"   Pagos sin transacción: {pagos_sin_transaccion}")
            print(f"   Pagos con transacción: {pagos_con_transaccion}")
            print(f"   Total de transacciones: {total_transacciones}")
            
            # Mostrar algunas transacciones creadas
            cursor.execute("""
                SELECT t.id, t.cliente_dni, t.monto, t.estado, t.referencia, p.id as pago_id
                FROM transaccion t
                JOIN pago p ON t.id = p.transaccion_id
                WHERE t.referencia LIKE 'MIG-%'
                LIMIT 5
            """)
            transacciones_migradas = cursor.fetchall()
            
            print("\n🔍 Últimas transacciones migradas:")
            for trans in transacciones_migradas:
                print(f"   Transacción {trans[0]} → Pago {trans[5]} | Cliente: {trans[1]} | ${trans[2]} | Estado: {trans[3]}")
                
    finally:
        connection.close()

if __name__ == "__main__":
    verificar_migracion()