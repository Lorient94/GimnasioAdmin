# Casos_de_uso/Pagos/procesar_pago_mercadopago.py
from typing import Dict, Any
from sqlmodel import Session, select
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL
from Adaptadores.adaptadorTransaccionSQL import AdaptadorTransaccionSQL
from servicios.mercado_pago import MercadoPagoService
from models.pago import Pago, EstadoPago
from models.transaccion import Transaccion, MetodoPago
from datetime import datetime
import uuid

class ProcesarPagoMercadoPagoCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_pagos = AdaptadorPagoSQL(session)
        self.repositorio_transacciones = AdaptadorTransaccionSQL(session)
        self.mercado_pago_service = MercadoPagoService()
    
    def ejecutar(self, pago_data: Dict[str, Any]) -> Dict[str, Any]:
        """Ejecutar el proceso completo de pago con Mercado Pago"""
        
        # Validar datos requeridos
        required_fields = ["cliente_dni", "monto", "concepto"]
        for field in required_fields:
            if field not in pago_data:
                return {"error": f"Campo requerido faltante: {field}"}
        
        try:
            # 1. Crear transacción
            transaccion = Transaccion(
                cliente_dni=pago_data["cliente_dni"],
                monto=float(pago_data["monto"]),
                metodo_pago=MetodoPago.MERCADO_PAGO,
                concepto=pago_data["concepto"],
                referencia=f"TRX-MP-{uuid.uuid4().hex[:8].upper()}"
            )
            
            transaccion_creada = self.repositorio_transacciones.crear_transaccion(transaccion)
            
            # 2. Crear pago asociado a la transacción
            pago_db = Pago(
                id_usuario=pago_data["cliente_dni"],
                transaccion_id=transaccion_creada.id,
                monto=float(pago_data["monto"]),
                concepto=pago_data["concepto"],
                metodo_pago="Mercado Pago",
                estado_pago=EstadoPago.PENDIENTE,
                referencia=f"PAGO-MP-{uuid.uuid4().hex[:8].upper()}"
            )
            
            pago_creado = self.repositorio_pagos.crear_pago(pago_db)
            
            # 3. Crear preferencia en Mercado Pago
            mp_data = {
                "cliente_dni": pago_data["cliente_dni"],
                "monto": float(pago_data["monto"]),
                "concepto": pago_data["concepto"],
                "pago_id": pago_creado.id
            }
            
            resultado_mp = self.mercado_pago_service.crear_preferencia_pago(mp_data)
            
            if "error" in resultado_mp:
                # Revertir la creación si hay error
                self.repositorio_pagos.eliminar_pago(pago_creado.id)
                self.repositorio_transacciones.eliminar_transaccion(transaccion_creada.id)
                return resultado_mp
            
            # 4. Actualizar pago con referencia de Mercado Pago
            self.repositorio_pagos.actualizar_pago(pago_creado.id, {
                "referencia_mp": resultado_mp["referencia_interna"],
                "preference_id": resultado_mp["preference_id"]
            })
            
            return {
                "success": True,
                "pago_id": pago_creado.id,
                "transaccion_id": transaccion_creada.id,
                "preference_id": resultado_mp["preference_id"],
                "init_point": resultado_mp["init_point"],
                "sandbox_init_point": resultado_mp.get("sandbox_init_point"),
                "referencia_interna": resultado_mp["referencia_interna"]
            }
            
        except Exception as e:
            return {"error": f"Error interno: {str(e)}"}