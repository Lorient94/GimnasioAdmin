# Casos_de_uso/Usuarios/eliminar_cliente_admin.py
from sqlmodel import Session
from Adaptadores.adaptadorClienteSQL import AdaptadorClienteSQL

class EliminarClienteAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorClienteSQL(session)
    
    def ejecutar(self, cliente_id: int) -> bool:
        cliente = self.repositorio.consultar_usuario_por_id(cliente_id)
        if not cliente:
            raise ValueError("Cliente no encontrado")
        
        # Verificar si tiene inscripciones activas (si aplica)
        # inscripciones_activas = self.repositorio.obtener_inscripciones_activas(cliente_id)
        # if inscripciones_activas:
        #     raise ValueError("No se puede eliminar un cliente con inscripciones activas")
        
        return self.repositorio.eliminar_usuario_permanentemente(cliente_id)
    
    def ejecutar_por_dni(self, dni: str) -> bool:
        cliente = self.repositorio.consultar_usuario(dni)
        if not cliente:
            raise ValueError("Cliente no encontrado")
        
        return self.ejecutar(cliente.id)