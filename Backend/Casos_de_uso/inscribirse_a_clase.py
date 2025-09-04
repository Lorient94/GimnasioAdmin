from models.inscripcion import Inscripcion
from Dominio.repositorios.repositorioInscripciones import RepositorioInscripciones

def inscribirse_a_clase(inscripcion_data: dict, repositorio: RepositorioInscripciones) -> Inscripcion:
    print(f"DEBUG CASO USO: Datos recibidos: {inscripcion_data}")
    
    # Crear la instancia de Inscripcion
    db_inscripcion = Inscripcion(**inscripcion_data)
    print(f"DEBUG CASO USO: Inscripción creada: {db_inscripcion}")
    
    inscripcion_creada = repositorio.crear_inscripcion(db_inscripcion)
    if not inscripcion_creada:
        raise ValueError("No se pudo inscribir a la clase")
    
    print(f"DEBUG CASO USO: Inscripción guardada en BD: {inscripcion_creada}")
    return inscripcion_creada