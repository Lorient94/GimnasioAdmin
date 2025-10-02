from abc import ABC, abstractmethod
from typing import List, Optional
from models.inscripcion import Inscripcion, EstadoInscripcion, InscripcionRead

class RepositorioInscripciones(ABC):
    @abstractmethod
    def crear_inscripcion(self, inscripcion: Inscripcion) -> Inscripcion:
        pass

    @abstractmethod
    def consultar_inscripcion(self, inscripcion_id: int) -> Optional[Inscripcion]:
        pass
    
    @abstractmethod
    def consultar_inscripcion_completa(self, inscripcion_id: int) -> Optional[InscripcionRead]:
        pass
        
    @abstractmethod
    def listar_todas_las_inscripciones(self) -> List[InscripcionRead]:
        pass
    
    @abstractmethod
    def actualizar_inscripcion(self, inscripcion_id: int, datos_actualizacion: dict) -> Optional[Inscripcion]:
        pass

    @abstractmethod
    def eliminar_inscripcion(self, inscripcion_id: int) -> bool:
        pass

    @abstractmethod
    def cancelar_inscripcion(self, inscripcion_id: int, motivo: Optional[str] = None) -> bool:
        pass

    @abstractmethod
    def reactivar_inscripcion(self, inscripcion_id: int) -> Optional[Inscripcion]:
        pass
    
    @abstractmethod
    def completar_inscripcion(self, inscripcion_id: int) -> bool:
        pass

    @abstractmethod
    def ver_inscripciones_cliente(self, cliente_dni: str) -> List[Inscripcion]:
        pass

    @abstractmethod
    def ver_inscripciones_clase(self, clase_id: int) -> List[Inscripcion]:
        pass

    @abstractmethod
    def listar_todas_las_inscripciones(self) -> List[InscripcionRead]:
        pass
    
    @abstractmethod
    def consultar_inscripcion_completa(self, inscripcion_id: int) -> Optional[InscripcionRead]:
        pass

    @abstractmethod
    def marcar_pagado(self, inscripcion_id: int) -> bool:
        pass
    

    @abstractmethod
    def obtener_estadisticas(self) -> dict:
        pass