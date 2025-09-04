from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any
from models.transaccion import Transaccion, EstadoPago, MetodoPago
from datetime import datetime

class RepositorioTransaccion(ABC):
    @abstractmethod
    def crear_transaccion(self, transaccion: Transaccion) -> Transaccion:
        pass

    @abstractmethod
    def consultar_transaccion(self, transaccion_id: int) -> Optional[Transaccion]:
        pass

    @abstractmethod
    def consultar_transaccion_por_referencia(self, referencia: str) -> Optional[Transaccion]:
        pass

    @abstractmethod
    def actualizar_transaccion(self, transaccion_id: int, datos_actualizacion: Dict[str, Any]) -> Optional[Transaccion]:
        pass

    @abstractmethod
    def eliminar_transaccion(self, transaccion_id: int) -> bool:
        pass

    @abstractmethod
    def cambiar_estado_transaccion(self, transaccion_id: int, estado: EstadoPago, observaciones: Optional[str] = None) -> bool:
        pass

    @abstractmethod
    def abrir_url_comprobante(self, transaccion_id: int) -> Optional[str]:
        pass

    @abstractmethod
    def ver_historial_transacciones(self, cliente_dni: str) -> List[Transaccion]:
        pass

    @abstractmethod
    def ver_todas(self) -> List[Transaccion]:
        pass

    @abstractmethod
    def listar_transacciones(self, 
                           estado: Optional[EstadoPago] = None,
                           cliente_dni: Optional[str] = None,
                           metodo_pago: Optional[MetodoPago] = None,
                           fecha_inicio: Optional[datetime] = None,
                           fecha_fin: Optional[datetime] = None) -> List[Transaccion]:
        pass

    @abstractmethod
    def obtener_estadisticas_totales(self) -> Dict[str, Any]:
        pass

    @abstractmethod
    def obtener_estadisticas_metodos_pago(self) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    def ver_transacciones_ultimo_mes(self, cliente_dni: str) -> List[Transaccion]:
        pass