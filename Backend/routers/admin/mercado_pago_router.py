# routers/admin/mercado_pago_router.py - VERSIÓN CON MODO SIMULADO AUTOMÁTICO
from fastapi import APIRouter, HTTPException, Depends
from sqlmodel import Session
from typing import Dict, Any, Optional
import os
import uuid

from database import get_session
from models.pago import Pago, EstadoPago
from models.transaccion import Transaccion
# ✅ DETECCIÓN SIMPLE: Verificar si el token existe y parece válido
def obtener_servicio_mercado_pago():
    """Obtener el servicio de Mercado Pago (real o simulado)"""
    token = os.getenv('MERCADOPAGO_ACCESS_TOKEN')
    
    # Si no hay token o es el token de prueba conocido, usar simulado
    if not token or token == "TEST-2016324737939080-121115-9a3f848d9f8f8e7f8f8f8f8f8f8f8f8f-201632473":
        print("🎭 Activando Mercado Pago Simulado (token no válido)")
        from servicios.mercado_pago_simulado import MercadoPagoSimulado
        return MercadoPagoSimulado(), "SIMULADO"
    else:
        try:
            print("🔑 Intentando conectar a Mercado Pago Real...")
            from servicios.mercado_pago import MercadoPagoService
            servicio = MercadoPagoService()
            print("✅ Mercado Pago Real - Conectado")
            return servicio, "REAL"
        except Exception as e:
            print(f"❌ Error con Mercado Pago Real: {e}")
            print("🎭 Cambiando a modo simulado...")
            from servicios.mercado_pago_simulado import MercadoPagoSimulado
            return MercadoPagoSimulado(), "SIMULADO"

# Obtener servicio y modo
MP_SERVICE, MODO_ACTUAL = obtener_servicio_mercado_pago()

mercado_pago_router = APIRouter(prefix="/api/mercado-pago", tags=["mercado-pago"])

@mercado_pago_router.get("/info")
def info_modo():
    """Información del modo actual"""
    return {
        "modo": MODO_ACTUAL,
        "mensaje": "Sistema funcionando en modo desarrollo" if MODO_ACTUAL == "SIMULADO" else "Sistema conectado a Mercado Pago real",
        "instrucciones": "Los pagos se simulan localmente" if MODO_ACTUAL == "SIMULADO" else "Los pagos usan Mercado Pago real"
    }

@mercado_pago_router.get("/test")
def test_endpoint():
    return {"message": f"✅ Mercado Pago router funcionando - Modo: {MODO_ACTUAL}"}

@mercado_pago_router.get("/pagos")
def obtener_pagos(db: Session = Depends(get_session)):
    """Obtener todos los pagos"""
    try:
        pagos = db.query(Pago).all()
        return {
            "modo": MODO_ACTUAL,
            "total_pagos": len(pagos),
            "pagos": [pago.dict() for pago in pagos]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obteniendo pagos: {str(e)}")


# routers/admin/mercado_pago_router.py - ENDPOINT MEJORADO
@mercado_pago_router.post("/crear-pago-prueba")
def crear_pago_prueba(
    pago_data: Dict[str, Any],
    db: Session = Depends(get_session)
):
    """Crear un pago de prueba CON TRANSACCIÓN - VERSIÓN CORREGIDA"""
    try:
        print(f"🎯 Recibiendo solicitud de pago prueba - Modo: {MODO_ACTUAL}")
        
        # Validar datos básicos
        if not pago_data.get("monto") or not pago_data.get("concepto"):
            raise HTTPException(status_code=400, detail="Faltan monto o concepto")
        
        # 1. CREAR TRANSACCIÓN PRIMERO
        print("💳 Creando transacción...")
        transaccion = Transaccion(
            cliente_dni=pago_data.get("cliente_dni", "12345678"),
            monto=float(pago_data["monto"]),
            concepto=pago_data["concepto"],
            metodo_pago=MetodoPago.MERCADO_PAGO,  # ✅ USAR EL ENUM CORRECTO
            referencia=f"TRX-{uuid.uuid4().hex[:8].upper()}",
            estado=EstadoTransaccion.PENDIENTE  # ✅ USAR EL ENUM CORRECTO
        )
        
        db.add(transaccion)
        db.commit()
        db.refresh(transaccion)
        print(f"✅ Transacción creada con ID: {transaccion.id}")
        
        # 2. Usar el servicio (real o simulado) para crear preferencia
        print("📤 Creando preferencia de pago...")
        resultado_mp = MP_SERVICE.crear_preferencia_pago(pago_data)
        
        if "error" in resultado_mp:
            # Si hay error, eliminar la transacción creada
            db.delete(transaccion)
            db.commit()
            raise HTTPException(status_code=400, detail=resultado_mp["error"])
        
        print("💾 Guardando pago en base de datos...")
        # 3. Crear pago en base de datos ASOCIADO A LA TRANSACCIÓN
        pago_db = Pago(
            id_usuario=pago_data.get("cliente_dni", "12345678"),
            transaccion_id=transaccion.id,  # ✅ ASOCIAR CON TRANSACCIÓN
            monto=float(pago_data["monto"]),
            concepto=pago_data["concepto"],
            metodo_pago="mercado_pago",
            estado_pago=EstadoPago.PENDIENTE,  # ✅ ESTE ES EL ESTADO DEL PAGO
            referencia=resultado_mp["referencia_interna"],
            preference_id=resultado_mp["preference_id"]
        )
        
        db.add(pago_db)
        db.commit()
        db.refresh(pago_db)
        
        print(f"✅ Pago guardado con ID: {pago_db.id}, asociado a transacción: {transaccion.id}")
        
        return {
            "success": True,
            "modo": MODO_ACTUAL,
            "pago_id": pago_db.id,
            "transaccion_id": transaccion.id,
            "preference_id": resultado_mp["preference_id"],
            "init_point": resultado_mp.get("sandbox_init_point") or resultado_mp.get("init_point"),
            "referencia": resultado_mp["referencia_interna"],
            "message": "Pago y transacción creados exitosamente"
        }
        
    except Exception as e:
        print(f"💥 Error inesperado: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")

@mercado_pago_router.post("/simular-pago-exitoso/{preference_id}")
def simular_pago_exitoso(
    preference_id: str,
    db: Session = Depends(get_session)
):
    """Simular un pago exitoso - ACTUALIZAR TRANSACCIÓN TAMBIÉN - VERSIÓN CORREGIDA"""
    try:
        print(f"🎯 Simulando pago exitoso para: {preference_id}")
        
        # Buscar pago local
        pago = db.query(Pago).filter(Pago.preference_id == preference_id).first()
        if not pago:
            raise HTTPException(status_code=404, detail="Pago no encontrado")
        
        # Buscar transacción asociada
        transaccion = None
        if pago.transaccion_id:
            transaccion = db.query(Transaccion).filter(Transaccion.id == pago.transaccion_id).first()
        
        # Actualizar estado del pago
        pago.estado_pago = EstadoPago.COMPLETADO
        pago.fecha_actualizacion = datetime.utcnow()
        pago.observaciones = f"Pago simulado exitosamente - {MODO_ACTUAL}"
        
        # Actualizar transacción si existe
        if transaccion:
            transaccion.estado = EstadoTransaccion.COMPLETADA  # ✅ USAR EL ENUM CORRECTO
            transaccion.fecha_actualizacion = datetime.utcnow()
            transaccion.observaciones = f"Transacción completada por pago simulado - Pago ID: {pago.id}"
            print(f"✅ Transacción {transaccion.id} actualizada a COMPLETADA")
        
        db.commit()
        
        return {
            "success": True,
            "modo": MODO_ACTUAL,
            "pago_id": pago.id,
            "transaccion_id": pago.transaccion_id,
            "preference_id": preference_id,
            "estado_pago": "completado",
            "estado_transaccion": "completada" if transaccion else "no_encontrada",
            "message": "Pago y transacción simulados exitosamente"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error simulando pago: {str(e)}")
@mercado_pago_router.get("/tarjetas-prueba")
def obtener_tarjetas_prueba():
    """Obtener tarjetas de prueba"""
    return {
        "modo": MODO_ACTUAL,
        "tarjetas": {
            "visa_aprobada": "4509 9535 6623 3704",
            "mastercard_aprobada": "5031 7557 3453 0604",
            "visa_rechazada": "4000 0000 0000 0004"
        },
        "instrucciones": {
            "cvv": "123",
            "fecha": "11/2025", 
            "email": "test_user_12345@testuser.com",
            "nota": "En modo simulado, usa cualquier dato"
        } if MODO_ACTUAL == "REAL" else {
            "cvv": "Cualquier código de 3 dígitos",
            "fecha": "Cualquier fecha futura",
            "email": "cualquier@email.com",
            "nota": "MODO SIMULADO - No se validan los datos"
        }
    }

@mercado_pago_router.get("/diagnostico")
def diagnostico_completo(db: Session = Depends(get_session)):
    """Diagnóstico completo del sistema"""
    try:
        count_pagos = db.query(Pago).count()
        
        return {
            "status": "ok",
            "modo": MODO_ACTUAL,
            "database": {
                "conexion": "ok",
                "total_pagos": count_pagos
            },
            "mercado_pago": {
                "modo": MODO_ACTUAL,
                "funcionando": True,
                "tipo": "Simulado" if MODO_ACTUAL == "SIMULADO" else "Real"
            },
            "mensaje": "✅ Sistema funcionando correctamente" if MODO_ACTUAL == "SIMULADO" else "✅ Conectado a Mercado Pago real"
        }
        
    except Exception as e:
        return {
            "status": "error",
            "modo": MODO_ACTUAL,
            "error": str(e)
        }
        
        
@mercado_pago_router.get("/transacciones-con-pagos")
def obtener_transacciones_con_pagos(
    cliente_dni: Optional[str] = None,
    db: Session = Depends(get_session)
):
    """Obtener transacciones con sus pagos asociados"""
    try:
        query = db.query(Transaccion)
        
        if cliente_dni:
            query = query.filter(Transaccion.cliente_dni == cliente_dni)
        
        transacciones = query.order_by(Transaccion.fecha.desc()).all()
        
        resultado = []
        for transaccion in transacciones:
            transaccion_data = {
                "id": transaccion.id,
                "cliente_dni": transaccion.cliente_dni,
                "fecha": transaccion.fecha,
                "monto": transaccion.monto,
                "concepto": transaccion.concepto,
                "metodo_pago": transaccion.metodo_pago,
                "referencia": transaccion.referencia,
                "estado": transaccion.estado,
                "pagos": []
            }
            
            # Obtener pagos asociados a esta transacción
            pagos = db.query(Pago).filter(Pago.transaccion_id == transaccion.id).all()
            for pago in pagos:
                transaccion_data["pagos"].append({
                    "id": pago.id,
                    "estado_pago": pago.estado_pago,
                    "monto": pago.monto,
                    "referencia": pago.referencia,
                    "fecha_creacion": pago.fecha_creacion,
                    "fecha_actualizacion": pago.fecha_actualizacion
                })
            
            resultado.append(transaccion_data)
        
        return {
            "modo": MODO_ACTUAL,
            "total_transacciones": len(resultado),
            "transacciones": resultado
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obteniendo transacciones: {str(e)}")