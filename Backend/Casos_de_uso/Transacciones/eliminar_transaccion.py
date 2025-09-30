# Casos_de_uso/Transacciones/eliminar_transaccion_admin.py
from sqlmodel import Session
from models.transaccion import Transaccion, EstadoPago
from Adaptadores.adaptadorTransaccionSQL import AdaptadorTransaccionSQL

class EliminarTransaccionAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorTransaccionSQL(session)
    
    def ejecutar(self, transaccion_id: int) -> bool:
        # Verificar que la transacción existe
        transaccion = self.repositorio.consultar_transaccion(transaccion_id)
        if not transaccion:
            raise ValueError("Transacción no encontrada")
        
        # Prevenir eliminación de transacciones completadas (opcional)
        if transaccion.estado == EstadoPago.COMPLETADO:
            raise ValueError("No se puede eliminar una transacción completada")
        
        return self.repositorio.eliminar_transaccion_permanentemente(transaccion_id)