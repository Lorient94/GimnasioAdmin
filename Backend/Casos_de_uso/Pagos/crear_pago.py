# Casos_de_uso/Pagos/crear_pago_admin.py
from sqlmodel import Session, select
from models.pago import Pago
from models.cliente import Cliente
from models.transaccion import Transaccion
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL

class CrearPagoAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorPagoSQL(session)
    
    def ejecutar(self, pago_data: dict) -> Pago:
        # Validar que el usuario existe
        usuario = self.session.exec(select(Cliente).where(Cliente.dni == pago_data['id_usuario'])).first()
        if not usuario:
            raise ValueError("Usuario no encontrado")
        
        # Si se proporciona transacción_id, verificar que existe
        if pago_data.get('transaccion_id'):
            transaccion = self.session.get(Transaccion, pago_data['transaccion_id'])
            if not transaccion:
                raise ValueError("Transacción no encontrada")
        
        # Verificar si la referencia ya existe
        if pago_data.get('referencia'):
            existing_ref = self.repositorio.consultar_pago_por_referencia(pago_data['referencia'])
            if existing_ref:
                raise ValueError("Ya existe un pago con esta referencia")
        
        # Crear el pago
        db_pago = Pago(**pago_data)
        return self.repositorio.crear_pago(db_pago)