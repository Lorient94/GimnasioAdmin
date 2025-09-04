from abc import ABC, abstractmethod
from typing import Optional, List
from models.cliente import Cliente

class RepositorioCliente(ABC):
    @abstractmethod
    def crear_usuario(self, cliente: Cliente) -> Cliente:
        pass

    @abstractmethod
    def iniciar_sesion(self, correo: str, password: str) -> Optional[Cliente]:
        pass

    @abstractmethod
    def modificar_usuario(self, dni: str, datos_actualizados: dict) -> Optional[Cliente]:
        pass

    @abstractmethod
    def consultar_usuario(self, dni: str) -> Optional[Cliente]:
        pass

    @abstractmethod
    def consultar_usuario_por_id(self, id: int) -> Optional[Cliente]:
        pass

    @abstractmethod
    def consultar_usuario_por_correo(self, correo: str) -> Optional[Cliente]:
        pass

    @abstractmethod
    def listar_usuarios(self, activos: bool = True) -> List[Cliente]:
        pass

    @abstractmethod
    def eliminar_usuario(self, dni: str) -> bool:
        pass

    @abstractmethod
    def autenticar_correo(self, correo: str) -> bool:
        pass

    @abstractmethod
    def contar_usuarios(self) -> int:
        pass