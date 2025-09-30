from Dominio.repositorios.repositorioClase import RepositorioClase
from typing import List, Optional
from models.clase import Clase

def consultar_clases(
    repositorio: RepositorioClase,
    activas: bool = True,
    instructor: Optional[str] = None,
    horario: Optional[str] = None
) -> List[Clase]:
    """
    Caso de uso: Consultar clases con filtros opcionales.
    """
    return repositorio.listar_clases(
        activas=activas,
        instructor=instructor,
        horario=horario
    )