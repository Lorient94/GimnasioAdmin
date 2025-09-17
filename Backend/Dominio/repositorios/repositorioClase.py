from abc import ABC, abstractmethod
from typing import List, Optional
from models.clase import Clase
from models.inscripcion import Inscripcion

class RepositorioClase(ABC):
    @abstractmethod
    def crear_clase(self, clase: Clase) -> Clase:
        pass

    @abstractmethod
    def obtener_clase_por_id(self, clase_id: int) -> Optional[Clase]:
        pass

    @abstractmethod
    def obtener_clase_por_nombre(self, nombre: str) -> Optional[Clase]:
        pass

    @abstractmethod
    def listar_clases(self, activas: bool = True, instructor: Optional[str] = None) -> List[Clase]:
        pass

    @abstractmethod
    def listar_clases_por_instructor(self, instructor: str) -> List[Clase]:
        pass

    @abstractmethod
    def listar_clases_por_dificultad(self, dificultad: str, activas: bool = True) -> List[Clase]:
        pass

    @abstractmethod
    def actualizar_clase(self, clase_id: int, datos_actualizados: dict) -> Optional[Clase]:
        pass

    @abstractmethod
    def eliminar_clase(self, clase_id: int) -> bool:
        pass

    @abstractmethod
    def activar_clase(self, clase_id: int) -> Optional[Clase]:
        pass

    @abstractmethod
    def verificar_nombre_existente(self, nombre: str, excluir_id: Optional[int] = None) -> bool:
        pass
    
    @abstractmethod
    def listar_clases_por_dia_hora(self, dia_semana: str, hora: str) -> List[Clase]:
        pass