# scripts/migrar_pagos_fix.py - VERSIÓN ALTERNATIVA
import sys
import os

# Agregar el directorio actual al path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

try:
    from sqlmodel import Session, select, create_engine
    from models.pago import Pago, EstadoPago
    from models.transaccion import Transaccion, MetodoPago, EstadoTransaccion
    
    # Configurar engine directamente si es necesario
    DATABASE_URL = "mysql+pymysql://root:123456@localhost:3308/gimnasio"
    engine = create_engine(DATABASE_URL, echo=True)
    
    def migrar_pagos_sin_transaccion():
        """Migrar pagos existentes que no tienen transacción asociada"""
        with Session(engine) as session:
            # Buscar pagos sin transacción
            pagos_sin_transaccion = session.exec(
                select(Pago).where(Pago.transaccion_id == None)
            ).all()
            
            print(f"🔍 Encontrados {len(pagos_sin_transaccion)} pagos sin transacción")
            
            for pago in pagos_sin_transaccion:
                print(f"🔄 Migrando pago ID: {pago.id}, Usuario: {pago.id_usuario}")
                
                # Mapear estado del pago al estado de la transacción
                estado_transaccion_map = {
                    EstadoPago.PENDIENTE: EstadoTransaccion.PENDIENTE,
                    EstadoPago.COMPLETADO: EstadoTransaccion.COMPLETADA,
                    EstadoPago.RECHAZADO: EstadoTransaccion.RECHAZADA,
                    EstadoPago.CANCELADO: EstadoTransaccion.CANCELADA,
                    EstadoPago.REEMBOLSADO: EstadoTransaccion.REEMBOLSADA
                }
                
                estado_transaccion = estado_transaccion_map.get(pago.estado_pago, EstadoTransaccion.PENDIENTE)
                
                # Crear transacción para este pago
                transaccion = Transaccion(
                    cliente_dni=pago.id_usuario,
                    monto=pago.monto,
                    concepto=pago.concepto or f"Pago migrado #{pago.id}",
                    metodo_pago=MetodoPago.MERCADO_PAGO,
                    referencia=f"MIG-{pago.referencia or pago.id}",
                    estado=estado_transaccion,
                    fecha=pago.fecha_creacion,
                    fecha_actualizacion=pago.fecha_actualizacion
                )
                
                session.add(transaccion)
                session.commit()
                session.refresh(transaccion)
                
                # Asociar pago con la transacción
                pago.transaccion_id = transaccion.id
                session.add(pago)
                session.commit()
                
                print(f"✅ Pago {pago.id} asociado a transacción {transaccion.id}")
            
            print("🎉 Migración completada!")
    
    if __name__ == "__main__":
        migrar_pagos_sin_transaccion()

except ImportError as e:
    print(f"❌ Error de importación: {e}")
    print("📁 Directorio actual:", os.getcwd())
    print("📁 Archivos en directorio actual:", os.listdir('.'))
    print("📁 Archivos en directorio padre:", os.listdir('..'))