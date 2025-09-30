from models.cliente import ClienteUpdate, Cliente
from Dominio.repositorios.repositorioCliente import RepositorioCliente

def editar_perfil(dni: str, datos_actualizados: dict, repositorio: RepositorioCliente) -> Cliente:
    cliente_actualizado = repositorio.modificar_usuario(dni, datos_actualizados)
    if not cliente_actualizado:
        raise ValueError("No se pudo actualizar el perfil")
    return cliente_actualizado# Casos_de_uso/Usuarios/editar_perfil.py
from sqlmodel import Session
from models.cliente import ClienteUpdate, Cliente
from Adaptadores.adaptadorClienteSQL import AdaptadorClienteSQL
from Dominio.repositorios.repositorioCliente import RepositorioCliente

# Función existente (mantener para compatibilidad)
def editar_perfil(dni: str, datos_actualizados: dict, repositorio: RepositorioCliente) -> Cliente:
    cliente_actualizado = repositorio.modificar_usuario(dni, datos_actualizados)
    if not cliente_actualizado:
        raise ValueError("No se pudo actualizar el perfil")
    return cliente_actualizado

# Clase para administración (más robusta)
class ModificarClienteAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorClienteSQL(session)
    
    def ejecutar(self, cliente_id: int, datos_actualizados: dict) -> Cliente:
        # Obtener cliente por ID
        cliente = self.repositorio.consultar_usuario_por_id(cliente_id)
        if not cliente:
            raise ValueError("Cliente no encontrado")
        
        # Validar datos usando ClienteUpdate
        update_data = ClienteUpdate(**datos_actualizados)
        
        # Verificar unicidad de DNI si se está actualizando
        if update_data.dni and update_data.dni != cliente.dni:
            cliente_existente = self.repositorio.consultar_usuario(update_data.dni)
            if cliente_existente and cliente_existente.id != cliente_id:
                raise ValueError("Ya existe otro cliente con ese DNI")
        
        # Verificar unicidad de correo si se está actualizando
        if update_data.correo and update_data.correo != cliente.correo:
            if self.repositorio.verificar_correo_existente(update_data.correo, excluir_id=cliente_id):
                raise ValueError("Ya existe otro cliente con ese correo")
        
        # Filtrar solo los campos que no son None
        datos_filtrados = {k: v for k, v in datos_actualizados.items() if v is not None}
        
        return self.repositorio.modificar_usuario(cliente.dni, datos_filtrados)
    
    def ejecutar_por_dni(self, dni: str, datos_actualizados: dict) -> Cliente:
        cliente = self.repositorio.consultar_usuario(dni)
        if not cliente:
            raise ValueError("Cliente no encontrado")
        
        return self.ejecutar(cliente.id, datos_actualizados)

# Alias para mantener compatibilidad
ModificarClienteCase = ModificarClienteAdminCase