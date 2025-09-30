# Casos_de_uso/Transacciones/crear_transaccion_admin.py
from sqlmodel import Session, select
from models.transaccion import Transaccion
from models.cliente import Cliente
from Adaptadores.adaptadorTransaccionSQL import AdaptadorTransaccionSQL

class CrearTransaccionAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorTransaccionSQL(session)
    
    def ejecutar(self, transaccion_data: dict) -> Transaccion:
        # Validar que el cliente existe
        cliente = self.session.exec(select(Cliente).where(Cliente.dni == transaccion_data['cliente_dni'])).first()
        if not cliente:
            raise ValueError("Cliente no encontrado")
        
        # Verificar si la referencia ya existe
        if transaccion_data.get('referencia'):
            existing_ref = self.repositorio.consultar_transaccion_por_referencia(transaccion_data['referencia'])
            if existing_ref:
                raise ValueError("Ya existe una transacción con esta referencia")
        
        # Crear la transacción
        db_transaccion = Transaccion(**transaccion_data)
        return self.repositorio.crear_transaccion(db_transaccion)