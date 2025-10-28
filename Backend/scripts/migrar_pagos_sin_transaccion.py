# scripts/migrar_pagos_sin_transaccion.py - VERSIÓN CORREGIDA
import sys
import os
from datetime import datetime

# Agregar el directorio padre al path para imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlmodel import Session, select
from database import engine
from models.pago import Pago, EstadoPago
from models.transaccion import Transaccion, MetodoPago, EstadoTransaccion

def migrar_pagos_sin_transaccion():
    """Migrar pagos existentes que no tienen transacción asociada - VERSIÓN CORREGIDA"""
    with Session(engine) as session:
        # Buscar pagos sin transacción
        pagos_sin_transaccion = session.exec(
            select(Pago).where(Pago.transaccion_id == None)
        ).all()
        
        print(f"🔍 Encontrados {len(pagos_sin_transaccion)} pagos sin transacción")
        
        for pago in pagos_sin_transaccion:
            print(f"🔄 Migrando pago ID: {pago.id}, Usuario: {pago.id_usuario}, Estado: {pago.estado_pago}")
            
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
            
            print(f"✅ Pago {pago.id} asociado a transacción {transaccion.id} (Estado: {estado_transaccion})")
        
        print("🎉 Migración completada!")

if __name__ == "__main__":
    migrar_pagos_sin_transaccion()