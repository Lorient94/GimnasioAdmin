# Casos_de_uso/actualizar_estado_usuario.py
from sqlmodel import Session
from Adaptadores.adaptadorClienteSQL import AdaptadorClienteSQL


class ActualizarEstadoUsuarioCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_clientes = AdaptadorClienteSQL(session)
    
    def ejecutar(self, dni: str, activo: bool, motivo: str = None) -> bool:
        usuario = self.repositorio_clientes.consultar_cliente(dni)
        if not usuario:
            raise ValueError("Usuario no encontrado")
        
        if usuario.activo == activo:
            raise ValueError(f"El usuario ya está {'activo' if activo else 'inactivo'}")
        
        # Si se desactiva, cancelar inscripciones activas
        if not activo:
            self._cancelar_inscripciones_activas(dni, motivo)
        
        return self.repositorio_clientes.actualizar_estado(dni, activo, motivo)