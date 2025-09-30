# Casos_de_uso/Usuarios/registrar_usuario.py
from sqlmodel import Session
from models.cliente import ClienteCreate, Cliente
from Adaptadores.adaptadorClienteSQL import AdaptadorClienteSQL
from Dominio.repositorios.repositorioCliente import RepositorioCliente

# Función existente (mantener para compatibilidad)
def registrar_usuario(cliente_data: ClienteCreate, repositorio: RepositorioCliente) -> Cliente:
    print(f'📥 Datos recibidos en registrar_usuario: {cliente_data}')

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

# Clase para el admin router (modificada para aceptar dict)
class RegistrarUsuarioCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorClienteSQL(session)
    
    def ejecutar(self, cliente_data: dict) -> Cliente:
        # Convertir dict a ClienteCreate para validación
        cliente_create = ClienteCreate(**cliente_data)
        
        # Usar la función existente pero adaptada
        # Crear instancia de Cliente manualmente
        db_cliente = Cliente(
            dni=cliente_create.dni,
            nombre=cliente_create.nombre,
            fecha_nacimiento=cliente_create.fecha_nacimiento,
            telefono=cliente_create.telefono,
            correo=cliente_create.correo,
            ciudad=cliente_create.ciudad,
            genero=cliente_create.genero,
            password=cliente_create.dni,  # Password por defecto = DNI
            activo=True
        )
        
        # Verificar si el DNI ya existe
        if self.repositorio.consultar_usuario(cliente_create.dni):
            raise ValueError("Ya existe un usuario con ese DNI.")
        
        # Verificar si el correo ya existe
        if self.repositorio.autenticar_correo(cliente_create.correo):
            raise ValueError("Ya existe un usuario con ese correo.")
        
        return self.repositorio.crear_usuario(db_cliente)