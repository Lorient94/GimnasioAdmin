# routers/mercado_pago_router.py
from fastapi import APIRouter, HTTPException, Depends, Request, BackgroundTasks
from sqlalchemy import select
from sqlmodel import Session
from typing import Dict, Any
import json

from database import get_session
from Casos_de_uso.Pagos.procesar_pago_mercadopago import ProcesarPagoMercadoPagoCase
from Casos_de_uso.Pagos.verificar_estado_pago import VerificarEstadoPagoCase
from models import Pago, PagoCreate, Cliente, Transaccion, EstadoPago
from servicios.mercado_pago import MercadoPagoService
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL
from config import get_db, MP_ACCESS_TOKEN, FRONTEND_URL, BACKEND_URL
import requests
import uuid
from datetime import datetime

mercado_pago_router = APIRouter(prefix="/api/mercado-pago", tags=["mercado-pago"])

MP_BASE_URL = "https://api.mercadopago.com/checkout/preferences"
HEADERS = {"Authorization": f"Bearer {MP_ACCESS_TOKEN}"}

@mercado_pago_router.get("/pagos")
def obtener_historial_pagos(db: Session = Depends(get_db)):
    """Devuelve todos los pagos registrados"""
    pagos = db.exec(select(Pago)).all()
    return [pago.dict() for pago in pagos]

@mercado_pago_router.post("/crear-preferencia")
def crear_preferencia(pago_data: PagoCreate, db: Session = Depends(get_db)):
    """Crea una preferencia de pago en Mercado Pago y un registro local de Pago."""
    # Validar cliente
    cliente = db.exec(select(Cliente).where(Cliente.dni == pago_data.id_usuario)).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    # Crear una transacción (si no hay)
    transaccion = None
    if pago_data.transaccion_id:
        transaccion = db.get(Transaccion, pago_data.transaccion_id)
    if not transaccion:
        transaccion = Transaccion(
            fecha=datetime.utcnow(),
            monto=pago_data.monto or 0,
            descripcion=pago_data.concepto or "Pago de servicio"
        )
        db.add(transaccion)
        db.commit()
        db.refresh(transaccion)

    # Crear preferencia en Mercado Pago
    preferencia_data = {
        "items": [
            {
                "title": pago_data.concepto or "Servicio de gimnasio",
                "quantity": 1,
                "currency_id": "ARS",
                "unit_price": pago_data.monto or 0,
            }
        ],
        "payer": {
            "name": cliente.nombre,
            "email": cliente.correo,
        },
        "back_urls": {
            "success": f"{FRONTEND_URL}/pago/exitoso",
            "failure": f"{FRONTEND_URL}/pago/fallido",
            "pending": f"{FRONTEND_URL}/pago/pendiente",
        },
        "auto_return": "approved",
        "notification_url": f"{BACKEND_URL}/api/mercado-pago/webhook",
        "external_reference": str(uuid.uuid4()),
    }

    response = requests.post(MP_BASE_URL, json=preferencia_data, headers=HEADERS)
    if response.status_code != 201:
        raise HTTPException(status_code=response.status_code, detail=response.text)

    preferencia = response.json()

    # Crear registro local de pago
    nuevo_pago = Pago(
        id_usuario=pago_data.id_usuario,
        transaccion_id=transaccion.id,
        monto=pago_data.monto,
        concepto=pago_data.concepto,
        metodo_pago=pago_data.metodo_pago or "mercado_pago",
        estado_pago=EstadoPago.PENDIENTE,
        referencia=preferencia.get("id"),
    )
    db.add(nuevo_pago)
    db.commit()
    db.refresh(nuevo_pago)

    return {
        "sandbox_init_point": preferencia.get("sandbox_init_point"),
        "init_point": preferencia.get("init_point"),
        "pago_id": nuevo_pago.id,
        "transaccion_id": transaccion.id,
    }
    
@mercado_pago_router.post("/webhook")
async def webhook(
    request: Request, 
    background_tasks: BackgroundTasks,
    session: Session = Depends(get_session)
):
    """
    Webhook para notificaciones de Mercado Pago.
    Procesa la notificación y actualiza el estado del pago local.
    """
    try:
        data = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Payload inválido")

    payment_id = data.get("data", {}).get("id")
    if not payment_id:
        return {"message": "sin id de pago"}

    # Obtener info del pago desde Mercado Pago
    resp = requests.get(f"https://api.mercadopago.com/v1/payments/{payment_id}", headers=HEADERS)
    if resp.status_code != 200:
        return {"message": "error al consultar pago", "detalle": resp.text}

    pago_info = resp.json()
    referencia = pago_info.get("external_reference")
    estado = pago_info.get("status")

    # Buscar pago local por referencia
    pago = session.exec(select(Pago).where(Pago.referencia == referencia)).first()
    if pago:
        pago.estado_pago = EstadoPago[estado] if estado in EstadoPago.__members__ else EstadoPago.PENDIENTE
        pago.fecha_actualizacion = datetime.utcnow()
        session.add(pago)
        session.commit()

    return {"message": "notificación procesada", "estado": estado}
    
@mercado_pago_router.post("/crear-pago")
def crear_pago_mercadopago(
    pago_data: Dict[str, Any],
    session: Session = Depends(get_session)
):
    """Crear un pago a través de Mercado Pago"""
    caso_uso = ProcesarPagoMercadoPagoCase(session)
    resultado = caso_uso.ejecutar(pago_data)
    
    if "error" in resultado:
        raise HTTPException(status_code=400, detail=resultado["error"])
    
    return resultado

@mercado_pago_router.get("/verificar-pago/{pago_id}")
def verificar_pago(
    pago_id: int,
    session: Session = Depends(get_session)
):
    """Verificar el estado de un pago"""
    caso_uso = VerificarEstadoPagoCase(session)
    resultado = caso_uso.ejecutar(pago_id)
    
    if "error" in resultado:
        raise HTTPException(status_code=400, detail=resultado["error"])
    
    return resultado


async def procesar_webhook_async(data: Dict[str, Any], session: Session):
    """Procesar webhook de forma asíncrona"""
    try:
        mp_service = MercadoPagoService()
        webhook_result = mp_service.procesar_webhook(data)
        
        if webhook_result.get("processed"):
            # Buscar y actualizar pago local
            repositorio_pagos = AdaptadorPagoSQL(session)
            
            # Buscar pago por referencia externa
            pago = repositorio_pagos.consultar_pago_por_referencia_mp(
                webhook_result["external_reference"]
            )
            
            if pago:
                # Actualizar estado usando el caso de uso
                caso_uso = VerificarEstadoPagoCase(session)
                caso_uso.ejecutar(pago.id)
                
    except Exception as e:
        print(f"Error procesando webhook async: {str(e)}")

@mercado_pago_router.post("/reembolsar/{pago_id}")
def reembolsar_pago(
    pago_id: int,
    monto: float = None,
    session: Session = Depends(get_session)
):
    """Reembolsar un pago de Mercado Pago"""
    repositorio_pagos = AdaptadorPagoSQL(session)
    pago = repositorio_pagos.consultar_pago(pago_id)
    
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    
    if not pago.referencia_mp:
        raise HTTPException(status_code=400, detail="Este pago no tiene referencia de Mercado Pago")
    
    mp_service = MercadoPagoService()
    
    # Buscar el payment_id (esto es una simplificación)
    # En producción necesitarías almacenar el payment_id cuando se complete el pago
    payment_info = mp_service.verificar_pago_por_referencia(pago.referencia_mp)
    
    if "error" in payment_info:
        raise HTTPException(status_code=400, detail=payment_info["error"])
    
    refund_result = mp_service.reembolsar_pago(payment_info["id"], monto)
    
    if "error" in refund_result:
        raise HTTPException(status_code=400, detail=refund_result["error"])
    
    # Actualizar estado local
    repositorio_pagos.cambiar_estado_pago(
        pago_id, 
        EstadoPago.REEMBOLSADO,
        f"Reembolsado via Mercado Pago. Refund ID: {refund_result['refund_id']}"
    )
    
    return {
        "success": True,
        "refund_id": refund_result["refund_id"],
        "status": refund_result["status"]
    }