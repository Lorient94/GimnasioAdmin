# Casos_de_uso/crear_clase.py
from typing import Dict, Any
from sqlmodel import Session
from Adaptadores.adaptadorClaseSQL import AdaptadorClaseSQL
from models.clase import Clase, ClaseCreate

class CrearClaseCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_clases = AdaptadorClaseSQL(session)
    
    def ejecutar(self, datos_clase: Dict[str, Any]) -> Clase:
        # Validaciones de negocio
        if not datos_clase.get('nombre'):
            raise ValueError("El nombre de la clase es requerido")
        
        if datos_clase.get('cupo_maximo', 0) <= 0:
            raise ValueError("El cupo máximo debe ser mayor a 0")
        
        # Mapear claves legacy a los nombres actuales del modelo
        datos = dict(datos_clase)
        if 'nivel_dificultad' in datos:
            datos['dificultad'] = datos.pop('nivel_dificultad')
        if 'duracion' in datos:
            datos['duracion_minutos'] = datos.pop('duracion')
        # Requisitos/materiales se aceptan pero no son columnas obligatorias
        # Si vienen, se almacenan en el objeto Clase como atributos dinámicos.
        clase = Clase(**{k: v for k, v in datos.items() if k in Clase.__fields__})
        # Adjuntar campos extra opcionales al objeto para compatibilidad
        for extra in ('requisitos', 'materiales_necesarios'):
            if extra in datos:
                setattr(clase, f'_{extra}', datos[extra])
        return self.repositorio_clases.crear_clase(clase)