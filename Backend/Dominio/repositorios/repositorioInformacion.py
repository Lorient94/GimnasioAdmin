from abc import ABC, abstractmethod
from typing import List, Optional
from datetime import datetime
from models.informacion import Informacion, InformacionStatsResponse, TipoInformacion

class RepositorioInformacion(ABC):
    @abstractmethod
    def crear_informacion(self, informacion: Informacion) -> Informacion:
        pass

    @abstractmethod
    def obtener_informacion_por_id(self, informacion_id: int) -> Optional[Informacion]:
        pass

    @abstractmethod
    def listar_informaciones(self, activas: bool = True, tipo: Optional[TipoInformacion] = None, destinatario_id: Optional[str] = None) -> List[Informacion]:
        pass

    @abstractmethod
    def listar_informaciones_por_tipo(self, tipo: TipoInformacion, activas: bool = True) -> List[Informacion]:
        pass

    @abstractmethod
    def listar_informaciones_por_cliente(self, cliente_dni: str) -> List[Informacion]:
        pass

    @abstractmethod
    def listar_alertas_activas(self) -> List[Informacion]:
        pass

    @abstractmethod
    def buscar_informaciones_por_palabra(self, palabra: str, activas: bool = True) -> List[Informacion]:
        pass

    @abstractmethod
    def buscar_informaciones_por_fecha(self, fecha: datetime, activas: bool = True) -> List[Informacion]:
        pass

    @abstractmethod
    def actualizar_informacion(self, informacion_id: int, datos_actualizados: dict) -> Optional[Informacion]:
        pass

    @abstractmethod
    def eliminar_informacion(self, informacion_id: int) -> bool:
        pass

    @abstractmethod
    def activar_informacion(self, informacion_id: int) -> Optional[Informacion]:
        pass

    @abstractmethod
    def desactivar_informacion(self, informacion_id: int) -> Optional[Informacion]:
        pass

    @abstractmethod
    def obtener_estadisticas(self) -> InformacionStatsResponse:
        pass