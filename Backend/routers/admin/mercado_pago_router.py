# routers/mercado_pago_router.py
from datetime import datetime
import os
import uuid
from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
import requests
from sqlalchemy import select
from sqlmodel import Session
from typing import Dict, Any
import json

from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL
from database import get_session
from Casos_de_uso.Pagos.procesar_pago_mercadopago import ProcesarPagoMercadoPagoCase
from Casos_de_uso.Pagos.verificar_estado_pago import VerificarEstadoPagoCase
from models.cliente import Cliente
from models.pago import EstadoPago, Pago, PagoCreate
from models.transaccion import Transaccion
from servicios.mercado_pago import MercadoPagoService

MP_ACCESS_TOKEN = os.getenv("MERCADOPAGO_ACCESS_TOKEN")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:3000")
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")
MP_BASE_URL = "https://api.mercadopago.com/checkout/preferences"
HEADERS = {"Authorization": f"Bearer {MP_ACCESS_TOKEN}"}

mercado_pago_router = APIRouter(prefix="/api/mercado-pago", tags=["mercado-pago"])
class PreferenciaCreate(BaseModel):
    cliente_dni: str
    monto: float
    
@mercado_pago_router.post("/crear-preferencia")
def crear_preferencia(preferencia: PreferenciaCreate, session: Session = Depends(get_session)):
    cliente = session.exec(select(Cliente).where(Cliente.dni == preferencia.cliente_dni)).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    transaccion = Transaccion(
        cliente_dni=cliente.dni,
        monto=preferencia.monto,
        fecha=datetime.utcnow(),
        estado=EstadoPago.PENDIENTE,
        referencia=f"MP-{uuid.uuid4().hex[:8].upper()}"
    )
    
    session.add(transaccion)
    session.commit()
    session.refresh(transaccion)
    
    return transaccion

@mercado_pago_router.post("/crear-pago")
def crear_pago_mercadopago(
    pago_data: Dict[str, Any],
    session: Session = Depends(get_session)
):
    """Crear un pago a través de Mercado Pago"""
    caso_uso = ProcesarPagoMercadoPagoCase(session)
    resultado = caso_uso.ejecutar(pago_data)
    return resultado

@mercado_pago_router.get("/verificar-pago/{pago_id}")
def verificar_pago(
    pago_id: int,
    session: Session = Depends(get_session)
):
    """Verificar el estado de un pago"""
    caso_uso = VerificarEstadoPagoCase(session)
    resultado = caso_uso.ejecutar(pago_id)
    return resultado

@mercado_pago_router.post("/webhook")
async def webhook_mercadopago(request: Request, session: Session = Depends(get_session)):
    """Webhook para notificaciones de Mercado Pago"""
    try:
        data = await request.json()
        
        # Mercado Pago envía el ID del pago
        if data.get("type") == "payment":
            payment_id = data["data"]["id"]
            
            # Usar el servicio para verificar el pago
            mp_service = MercadoPagoService()
            payment_info = mp_service.verificar_pago(payment_id)
            
            if "error" not in payment_info:
                # Buscar pago por referencia externa
                repositorio_pagos = AdaptadorPagoSQL(session)
                pago = repositorio_pagos.consultar_pago_por_referencia(
                    payment_info.get("external_reference", "")
                )
                
                if pago:
                    # Actualizar estado
                    caso_uso = VerificarEstadoPagoCase(session)
                    caso_uso.ejecutar(pago.id)
            
        return {"status": "ok"}
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error procesando webhook: {str(e)}")