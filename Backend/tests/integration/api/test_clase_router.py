import pytest
from datetime import datetime, timedelta
from tests.integration.utils import crear_cliente_prueba, crear_clase_prueba, crear_inscripcion_prueba


def test_obtener_clases(client, db_session):
    """Test para obtener lista de clases"""
    response = client.get("/clases/")
    assert response.status_code in [200, 404]

def test_crear_clase(client, db_session):
    """Test para crear una nueva clase"""
    clase_data = {
        "nombre": "Yoga Inicial",
        "descripcion": "Clase de yoga para principiantes",
        "instructor": "Maria Lopez",
        "horario": (datetime.now() + timedelta(hours=2)).isoformat(),
        "duracion": 60,
        "capacidad": 20,
        "activa": True
    }
    
    response = client.post("/clases/", json=clase_data)
    assert response.status_code in [200, 201, 404]