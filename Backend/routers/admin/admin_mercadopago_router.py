# routers/mercado_pago_router.py
from fastapi import APIRouter, HTTPException, Depends, Request, BackgroundTasks
from sqlmodel import Session
from typing import Dict, Any
import json

from database import get_session
from Casos_de_uso.Pagos.procesar_pago_mercadopago import ProcesarPagoMercadoPagoCase
from Casos_de_uso.Pagos.verificar_estado_pago import VerificarEstadoPagoCase
from models.pago import EstadoPago
from servicios.mercado_pago import MercadoPagoService
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL

mercado_pago_router = APIRouter(prefix="/api/mercado-pago", tags=["mercado-pago"])

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

@mercado_pago_router.post("/webhook")
async def webhook_mercadopago(
    request: Request, 
    background_tasks: BackgroundTasks,
    session: Session = Depends(get_session)
):
    """Webhook para notificaciones de Mercado Pago"""
    try:
        data = await request.json()
        
        # Procesar en segundo plano para responder rápido a MP
        background_tasks.add_task(procesar_webhook_async, data, session)
        
        return {"status": "ok", "processed": True}
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error procesando webhook: {str(e)}")

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