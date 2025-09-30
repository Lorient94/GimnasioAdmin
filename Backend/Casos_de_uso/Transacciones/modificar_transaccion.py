# Casos_de_uso/Transacciones/modificar_transaccion_admin.py
from sqlmodel import Session
from models.transaccion import Transaccion
from Adaptadores.adaptadorTransaccionSQL import AdaptadorTransaccionSQL

class ModificarTransaccionAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorTransaccionSQL(session)
    
    def ejecutar(self, transaccion_id: int, datos_actualizados: dict) -> Transaccion:
        # Verificar que la transacción existe
        transaccion = self.repositorio.consultar_transaccion(transaccion_id)
        if not transaccion:
            raise ValueError("Transacción no encontrada")
        
        # Validar que no se esté modificando una transacción completada
        if transaccion.estado == "completado" and any(key in datos_actualizados for key in ['monto', 'metodo_pago']):
            raise ValueError("No se puede modificar una transacción completada")
        
        return self.repositorio.actualizar_transaccion(transaccion_id, datos_actualizados)