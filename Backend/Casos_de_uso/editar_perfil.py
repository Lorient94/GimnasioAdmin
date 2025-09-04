from models.cliente import ClienteUpdate, Cliente
from Dominio.repositorios.repositorioCliente import RepositorioCliente

def editar_perfil(dni: str, datos_actualizados: dict, repositorio: RepositorioCliente) -> Cliente:
    cliente_actualizado = repositorio.modificar_usuario(dni, datos_actualizados)
    if not cliente_actualizado:
        raise ValueError("No se pudo actualizar el perfil")
    return cliente_actualizado