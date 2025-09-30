# tests/integration/utils.py
import random
import string
from datetime import datetime, timedelta
from sqlmodel import Session

def generar_dni_aleatorio():
    """Genera un DNI aleatorio de 8 dígitos"""
    return ''.join(random.choices(string.digits, k=8))

def crear_cliente_prueba(db: Session, **kwargs):
    from models.cliente import Cliente
    
    cliente_data = {
        "dni": generar_dni_aleatorio(),
        "nombre": "Test",
        "apellido": "Usuario", 
        "email": "test@example.com",
        "password": "password123",
        "telefono": "123456789",
        "fecha_registro": datetime.now().date(),
        "activo": True
    }
    cliente_data.update(kwargs)
    
    cliente = Cliente(**cliente_data)
    db.add(cliente)
    db.commit()
    db.refresh(cliente)
    
    return cliente

def crear_clase_prueba(db: Session, **kwargs):
    from models.clase import Clase
    
    clase_data = {
        "nombre": "Clase de Prueba",
        "descripcion": "Esta es una clase de prueba",
        "instructor": "Instructor Prueba",
        "horario": datetime.now() + timedelta(hours=1),
        "duracion": 60,
        "capacidad": 20,
        "activa": True
    }
    clase_data.update(kwargs)
    
    clase = Clase(**clase_data)
    db.add(clase)
    db.commit()
    db.refresh(clase)
    
    return clase

def crear_inscripcion_prueba(db: Session, cliente_id: int, clase_id: int, **kwargs):
    from models.inscripcion import Inscripcion
    
    inscripcion_data = {
        "cliente_id": cliente_id,
        "clase_id": clase_id,
        "fecha_inscripcion": datetime.now(),
        "estado": "confirmada"
    }
    inscripcion_data.update(kwargs)
    
    inscripcion = Inscripcion(**inscripcion_data)
    db.add(inscripcion)
    db.commit()
    db.refresh(inscripcion)
    
    return inscripcion