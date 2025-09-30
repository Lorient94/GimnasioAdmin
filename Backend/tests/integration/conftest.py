import pytest
import sys
import os
from fastapi.testclient import TestClient
from sqlmodel import create_engine, Session, SQLModel
from typing import Generator

# Agregar el directorio Backend al path de Python
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Ahora importamos desde app (no desde main)
from app import app
from database import get_session

# Usar SQLite en memoria para tests
@pytest.fixture(scope="session")
def engine():
    test_engine = create_engine("sqlite:///:memory:", echo=True)
    SQLModel.metadata.create_all(bind=test_engine)
    yield test_engine
    SQLModel.metadata.drop_all(bind=test_engine)

@pytest.fixture
def db_session(engine):
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()

@pytest.fixture
def client(db_session):
    def override_get_session() -> Generator[Session, None, None]:
        try:
            yield db_session
        finally:
            pass
    
    # Override la dependencia get_session
    app.dependency_overrides[get_session] = override_get_session
    with TestClient(app) as test_client:
        yield test_client
    
    app.dependency_overrides.clear()