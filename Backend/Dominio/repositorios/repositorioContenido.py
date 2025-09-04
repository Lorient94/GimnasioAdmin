from abc import ABC, abstractmethod
from typing import List, Optional
from datetime import datetime
from models.contenido import Contenido, ContenidoCategoriaResponse

class RepositorioContenido(ABC):
    @abstractmethod
    def crear_contenido(self, contenido: Contenido) -> Contenido:
        pass

    @abstractmethod
    def obtener_contenido_por_id(self, contenido_id: int) -> Optional[Contenido]:
        pass

    @abstractmethod
    def listar_contenidos(self, activos: bool = True, categoria: Optional[str] = None) -> List[Contenido]:
        pass

    @abstractmethod
    def listar_contenidos_por_categoria(self, categoria: str, activos: bool = True) -> List[Contenido]:
        pass

    @abstractmethod
    def listar_categorias(self) -> List[str]:
        pass

    @abstractmethod
    def listar_contenidos_agrupados_por_categoria(self) -> List[ContenidoCategoriaResponse]:
        pass

    @abstractmethod
    def buscar_contenidos(self, palabra_clave: str, activos: bool = True) -> List[Contenido]:
        pass

    @abstractmethod
    def buscar_contenidos_por_fecha(self, fecha_str: str, activos: bool = True) -> List[Contenido]:
        pass

    @abstractmethod
    def actualizar_contenido(self, contenido_id: int, datos_actualizados: dict) -> Optional[Contenido]:
        pass

    @abstractmethod
    def eliminar_contenido(self, contenido_id: int) -> bool:
        pass

    @abstractmethod
    def activar_contenido(self, contenido_id: int) -> Optional[Contenido]:
        pass

    @abstractmethod
    def descargar_contenido(self, contenido_id: int) -> Optional[bytes]:
        pass