# Casos_de_uso/Pagos/eliminar_pago_admin.py
from sqlmodel import Session
from models.pago import Pago, EstadoPago
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL

class EliminarPagoAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorPagoSQL(session)
    
    def ejecutar(self, pago_id: int) -> bool:
        # Verificar que el pago existe
        pago = self.repositorio.consultar_pago(pago_id)
        if not pago:
            raise ValueError("Pago no encontrado")
        
        # Prevenir eliminación de pagos completados (opcional)
        if pago.estado_pago == EstadoPago.COMPLETADO:
            raise ValueError("No se puede eliminar un pago completado")
        
        return self.repositorio.eliminar_pago_permanentemente(pago_id)