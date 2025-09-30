# models/__init__.py
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .pago import Pago
    from .transaccion import Transaccion
    from .cliente import Cliente
    from .clase import Clase
    from .inscripcion import Inscripcion