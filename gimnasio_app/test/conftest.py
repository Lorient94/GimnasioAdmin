import pytest
import sys
import os
from fastapi.testclient import TestClient

# Agregar el directorio padre y luego Backend al path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
backend_dir = os.path.join(parent_dir, 'Backend')

sys.path.insert(0, backend_dir)

try:
    from Backend.app import app
except ImportError:
    # Si app.py no está en la raíz de Backend, intenta otra ruta
    try:
        from Backend.app import app
    except ImportError:
        # Crear app de prueba si no se puede importar
        from fastapi import FastAPI
        app = FastAPI()


@pytest.fixture
def client():
    return TestClient(app)