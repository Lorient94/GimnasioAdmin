from fastapi import APIRouter, HTTPException, status, Depends
from sqlmodel import Session
from typing import List
from database import get_session
from models.cliente import (
    Cliente, ClienteCreate, ClienteRead, ClienteUpdate, 
    LoginRequest, VerificacionResponse
)
from Dominio.repositorios.repositorioCliente import RepositorioCliente
from Adaptadores.adaptadorClienteSQL import AdaptadorClienteSQL

from Casos_de_uso.registrar_usuario import registrar_usuario
from Casos_de_uso.iniciar_sesion import iniciar_sesion
from Casos_de_uso.editar_perfil import editar_perfil

cliente_router = APIRouter(prefix="/api/clientes", tags=["clientes"])

# Dependency para obtener el repositorio
def get_cliente_repository(session: Session = Depends(get_session)) -> RepositorioCliente:
    return AdaptadorClienteSQL(session)

@cliente_router.get("/", response_model=List[ClienteRead])
def list_clientes(
    activos: bool = True,
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener todos los clientes usando el repositorio"""
    return repository.listar_usuarios(activos)

@cliente_router.post("/", response_model=ClienteRead, status_code=status.HTTP_201_CREATED)
def create_cliente(
    cliente_data: ClienteCreate, 
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Registrar un nuevo cliente usando el caso de uso"""
    try:
        cliente_creado = registrar_usuario(cliente_data, repository)
        return cliente_creado
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error interno del servidor: {str(e)}"
        )

@cliente_router.get("/{cliente_id}", response_model=ClienteRead)
def get_cliente(
    cliente_id: int, 
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener un cliente por ID usando el repositorio"""
    cliente = repository.consultar_usuario_por_id(cliente_id)
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cliente

@cliente_router.get("/dni/{dni}", response_model=ClienteRead)
def get_cliente_by_dni(
    dni: str, 
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Obtener un cliente por DNI usando el repositorio"""
    cliente = repository.consultar_usuario(dni)
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cliente

@cliente_router.put("/{cliente_id}", response_model=ClienteRead)
def update_cliente(
    cliente_id: int,
    cliente_data: ClienteUpdate,
    session: Session = Depends(get_session),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    print(f"🎯 INICIANDO ACTUALIZACIÓN para cliente_id: {cliente_id}")
    print(f"📦 Datos recibidos: {cliente_data.dict()}")
    
    # Primero obtener el cliente para saber su DNI
    db_cliente = session.get(Cliente, cliente_id)
    if not db_cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    # Convertir a dict
    datos_actualizados = {}
    for key, value in cliente_data.dict().items():
        if value is not None:
            datos_actualizados[key] = value     
    print(f"🔧 Datos a actualizar: {datos_actualizados}")
    
    # Actualizar usando el repositorio
    cliente_actualizado = repository.modificar_usuario(db_cliente.dni, datos_actualizados)
    
    if not cliente_actualizado:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error al actualizar el cliente"
        )
    
    return cliente_actualizado


@cliente_router.delete("/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_cliente(
    cliente_id: int,
    session: Session = Depends(get_session),
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Eliminar (soft delete) un cliente"""
    # Primero obtener el cliente para saber su DNI
    from sqlmodel import select
    db_cliente = session.get(Cliente, cliente_id)
    if not db_cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    eliminado = repository.eliminar_usuario(db_cliente.dni)
    if not eliminado:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error al eliminar el cliente"
        )

@cliente_router.get("/verificar-correo/{correo}", response_model=VerificacionResponse)
def verificar_correo(
    correo: str, 
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Verificar si un correo existe usando el repositorio"""
    existe = repository.autenticar_correo(correo)
    return VerificacionResponse(existe=existe)

@cliente_router.get("/verificar-dni/{dni}", response_model=VerificacionResponse)
def verificar_dni(
    dni: str, 
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Verificar si un DNI existe"""
    cliente = repository.consultar_usuario(dni)
    return VerificacionResponse(existe=cliente is not None)

@cliente_router.post("/login", response_model=ClienteRead)
def login(
    login_data: LoginRequest, 
    repository: RepositorioCliente = Depends(get_cliente_repository)
):
    """Iniciar sesión usando el caso de uso"""
    print(f"🔐 Router: Login attempt for {login_data.correo}")
    
    try:
        cliente = iniciar_sesion(login_data.correo, login_data.password, repository)
        print(f"✅ Router: Login successful for {cliente.nombre}")
        return cliente
    except ValueError as e:
        print(f"❌ Router: Login failed - {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    
