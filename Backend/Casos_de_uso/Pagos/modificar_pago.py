# Casos_de_uso/Pagos/modificar_pago_admin.py
from sqlmodel import Session
from models.pago import Pago, EstadoPago
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL

class ModificarPagoAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorPagoSQL(session)
    
    def ejecutar(self, pago_id: int, datos_actualizados: dict) -> Pago:
        # Verificar que el pago existe
        pago = self.repositorio.consultar_pago(pago_id)
        if not pago:
            raise ValueError("Pago no encontrado")
        
        # Validar que no se esté modificando un pago completado
        if pago.estado_pago == EstadoPago.COMPLETADO and any(key in datos_actualizados for key in ['monto', 'metodo_pago']):
            raise ValueError("No se puede modificar un pago completado")
        
        return self.repositorio.actualizar_pago(pago_id, datos_actualizados)