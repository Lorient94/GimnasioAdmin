# models/enums.py
from enum import Enum

class EstadoTransaccion(str, Enum):
    PENDIENTE = "pendiente"
    COMPLETADA = "completada"
    RECHAZADA = "rechazada"
    CANCELADA = "cancelada"
    REEMBOLSADA = "reembolsada"

class EstadoPago(str, Enum):
    PENDIENTE = "pendiente"
    COMPLETADO = "completado"
    RECHAZADO = "rechazado"
    CANCELADO = "cancelado"
    REEMBOLSADO = "reembolsado"

class MetodoPago(str, Enum):
    TRANSFERENCIA = "transferencia"
    TARJETA_CREDITO = "tarjeta de crédito"
    TARJETA_DEBITO = "tarjeta de débito"
    BILLETERA_VIRTUAL = "billetera virtual"
    EFECTIVO = "efectivo"
    MERCADO_PAGO = "mercado_pago"