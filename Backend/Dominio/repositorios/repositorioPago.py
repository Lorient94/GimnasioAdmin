from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any
from models.pago import Pago, EstadoPago
from datetime import datetime

class RepositorioPago(ABC):
    @abstractmethod
    def crear_pago(self, pago: Pago) -> Pago:
        pass

    @abstractmethod
    def consultar_pago(self, pago_id: int) -> Optional[Pago]:
        pass

    @abstractmethod
    def consultar_pago_por_referencia(self, referencia: str) -> Optional[Pago]:
        pass

    @abstractmethod
    def actualizar_pago(self, pago_id: int, datos_actualizacion: Dict[str, Any]) -> Optional[Pago]:
        pass

    @abstractmethod
    def eliminar_pago(self, pago_id: int) -> bool:
        pass

    @abstractmethod
    def cambiar_estado_pago(self, pago_id: int, estado: EstadoPago, observaciones: Optional[str] = None) -> bool:
        pass

    @abstractmethod
    def completar_pago(self, pago_id: int) -> bool:
        pass

    @abstractmethod
    def rechazar_pago(self, pago_id: int) -> bool:
        pass

    @abstractmethod
    def listar_pagos(self, 
                   estado_pago: Optional[EstadoPago] = None,
                   id_usuario: Optional[str] = None,
                   transaccion_id: Optional[int] = None) -> List[Pago]:
        pass

    @abstractmethod
    def obtener_pagos_usuario(self, usuario_dni: str) -> List[Pago]:
        pass

    @abstractmethod
    def obtener_pagos_transaccion(self, transaccion_id: int) -> List[Pago]:
        pass

    @abstractmethod
    def obtener_estadisticas_totales(self) -> Dict[str, Any]:
        pass