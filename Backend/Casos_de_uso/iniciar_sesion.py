from models.cliente import Cliente
from Dominio.repositorios.repositorioCliente import RepositorioCliente

def iniciar_sesion(correo: str, password: str, repositorio: RepositorioCliente) -> Cliente:
    print(f"🔐 Caso de uso: Intentando login para {correo}")
    
    cliente = repositorio.iniciar_sesion(correo, password)
    
    if not cliente:
        print("❌ Caso de uso: Credenciales inválidas")
        raise ValueError("Credenciales inválidas")
    
    if not cliente.activo:
        print("❌ Caso de uso: Cuenta inactiva")
        raise ValueError("Cuenta inactiva")
    
    print(f"✅ Caso de uso: Login exitoso para {cliente.nombre}")
    return cliente