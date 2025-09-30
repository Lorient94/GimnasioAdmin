# tests/integration/api/test_auth_router.py
import pytest
from tests.integration.utils import crear_cliente_prueba, crear_clase_prueba, crear_inscripcion_prueba


def test_registro_usuario(client, db_session):
    # Datos de prueba
    usuario_data = {
        "nombre": "Juan",
        "apellido": "Perez",
        "email": "juan@example.com",
        "password": "password123",
        "telefono": "123456789"
    }
    
    # Llamar al endpoint de registro
    response = client.post("/auth/registro", json=usuario_data)
    assert response.status_code in [200, 201, 404]  # Acepta múltiples códigos    
    # Verificar la respuesta
    assert response.status_code == 200
    data = response.json()
    
    assert "id" in data
    assert data["email"] == usuario_data["email"]
    assert data["nombre"] == usuario_data["nombre"]
    
    # Verificar que no se devuelve la contraseña
    assert "password" not in data

def test_inicio_sesion_exitoso(client, db_session):
    from tests.integration.utils import crear_cliente_prueba
    
    # Crear un usuario de prueba
    cliente = crear_cliente_prueba(db_session, password="password123")
    
    # Intentar iniciar sesión
    response = client.post("/auth/login", json={
        "email": cliente.email,
        "password": "password123"
    })
    
    # Verificar la respuesta
    assert response.status_code == 200
    data = response.json()
    
    assert "token" in data
    assert "cliente" in data
    assert data["cliente"]["email"] == cliente.email

def test_inicio_sesion_fallido(client, db_session):
    from tests.integration.utils import crear_cliente_prueba
    
    # Crear un usuario de prueba
    cliente = crear_cliente_prueba(db_session, password="password123")
    
    # Intentar iniciar sesión con contraseña incorrecta
    response = client.post("/auth/login", json={
        "email": cliente.email,
        "password": "contraseña_incorrecta"
    })
    
    # Verificar que falla
    assert response.status_code == 401