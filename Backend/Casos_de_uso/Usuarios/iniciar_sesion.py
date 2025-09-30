# Casos_de_uso/Usuarios/iniciar_sesion.py
from sqlmodel import Session
from models.cliente import Cliente
from Adaptadores.adaptadorClienteSQL import AdaptadorClienteSQL

class IniciarSesionCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorClienteSQL(session)
    
    def ejecutar(self, correo: str, password: str) -> Cliente:
        cliente = self.repositorio.iniciar_sesion(correo, password)
        
        if not cliente:
            raise ValueError("Credenciales inválidas")
        
        if not cliente.activo:
            raise ValueError("Cuenta inactiva")
        
        return cliente

# Mantener la función existente para compatibilidad
def iniciar_sesion(correo: str, password: str, repositorio) -> Cliente:
    caso_uso = IniciarSesionCase(repositorio.session)
    return caso_uso.ejecutar(correo, password)