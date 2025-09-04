from models.cliente import ClienteCreate, Cliente
from Dominio.repositorios.repositorioCliente import RepositorioCliente

def registrar_usuario(cliente_data: ClienteCreate, repositorio: RepositorioCliente) -> Cliente:
    print(f'📥 Datos recibidos en registrar_usuario: {cliente_data}')

    """
    Caso de uso: Registrar un nuevo usuario (cliente) en el sistema.
    - Valida si el DNI o correo ya existen.
    - Crea el usuario si no existe.
    """
    # Verificar si el DNI ya existe
    if repositorio.consultar_usuario(cliente_data.dni):
        print('❌ Ya existe un usuario con ese DNI')
        raise ValueError("Ya existe un usuario con ese DNI.")

    # Verificar si el correo ya existe
    if repositorio.autenticar_correo(cliente_data.correo):
        print('❌ Ya existe un usuario con ese correo')
        raise ValueError("Ya existe un usuario con ese correo.")

    # Crear el usuario
    db_cliente = Cliente(
        dni=cliente_data.dni,
        nombre=cliente_data.nombre,
        fecha_nacimiento=cliente_data.fecha_nacimiento,
        telefono=cliente_data.telefono,
        correo=cliente_data.correo,
        ciudad=cliente_data.ciudad,
        genero=cliente_data.genero,
        password=cliente_data.dni,  # Password por defecto = DNI
        activo=True
    )
    print(f'✅ Creando cliente: {db_cliente}')
    resultado = repositorio.crear_usuario(db_cliente)
    print(f'📤 Cliente creado en repositorio: {resultado}')
    
    return resultado