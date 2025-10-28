# Casos_de_uso/Pagos/eliminar_pago_admin.py
from typing import Any, Dict
from sqlmodel import Session
from models.pago import Pago, EstadoPago
from Adaptadores.adaptadorPagoSQL import AdaptadorPagoSQL
from datetime import datetime

class EliminarPagoAdminCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorPagoSQL(session)
    
    def ejecutar(self, pago_id: int, motivo: str = "Eliminado por administrador", eliminado_por: str = "sistema") -> Dict[str, Any]:
        """
        Soft delete: marcar pago como inactivo en lugar de eliminarlo físicamente
        
        Args:
            pago_id: ID del pago a eliminar
            motivo: Razón de la eliminación
            eliminado_por: Identificador de quién realiza la eliminación
            
        Returns:
            Dict con información del resultado
        """
        try:
            # Verificar que el pago existe y está activo
            pago = self.repositorio.consultar_pago(pago_id)
            if not pago:
                return {
                    "success": False,
                    "error": "Pago no encontrado",
                    "pago_id": pago_id
                }
            
            # Validar políticas de negocio
            if pago.estado_pago == EstadoPago.COMPLETADO:
                return {
                    "success": False,
                    "error": "No se puede eliminar un pago completado por políticas de auditoría financiera",
                    "pago_id": pago_id,
                    "estado": pago.estado_pago.value
                }
            
            # Realizar soft delete
            resultado = self.repositorio.eliminar_pago(pago_id, motivo, eliminado_por)
            
            if resultado:
                return {
                    "success": True,
                    "message": f"Pago #{pago_id} marcado como eliminado",
                    "pago_id": pago_id,
                    "motivo": motivo,
                    "eliminado_por": eliminado_por,
                    "fecha_eliminacion": datetime.utcnow().isoformat(),
                    "tipo": "soft_delete"
                }
            else:
                return {
                    "success": False,
                    "error": "No se pudo eliminar el pago",
                    "pago_id": pago_id
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Error inesperado: {str(e)}",
                "pago_id": pago_id
            }

class RestaurarPagoAdminCase:
    """Caso de uso para restaurar pagos eliminados"""
    
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorPagoSQL(session)
    
    def ejecutar(self, pago_id: int) -> Dict[str, Any]:
        """Restaurar un pago que fue marcado como eliminado"""
        try:
            resultado = self.repositorio.restaurar_pago(pago_id)
            
            if resultado:
                return {
                    "success": True,
                    "message": f"Pago #{pago_id} restaurado exitosamente",
                    "pago_id": pago_id
                }
            else:
                return {
                    "success": False,
                    "error": "No se pudo restaurar el pago (puede que no exista o ya esté activo)",
                    "pago_id": pago_id
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Error restaurando pago: {str(e)}",
                "pago_id": pago_id
            }

class EliminarPagoPermanentementeCase:
    """Caso de uso para eliminación permanente (SOLO USO AVANZADO)"""
    
    def __init__(self, session: Session):
        self.session = session
        self.repositorio = AdaptadorPagoSQL(session)
    
    def ejecutar(self, pago_id: int) -> Dict[str, Any]:
        """Eliminación permanente - USAR SOLO EN CASOS EXTREMOS"""
        try:
            # Verificar que el pago existe y está marcado como eliminado
            pago = self.session.get(Pago, pago_id)
            if not pago:
                return {
                    "success": False,
                    "error": "Pago no encontrado",
                    "pago_id": pago_id
                }
            
            if pago.activo:
                return {
                    "success": False,
                    "error": "No se puede eliminar permanentemente un pago activo. Use soft delete primero.",
                    "pago_id": pago_id
                }
            
            resultado = self.repositorio.eliminar_pago_permanentemente(pago_id)
            
            if resultado:
                return {
                    "success": True,
                    "message": f"Pago #{pago_id} eliminado permanentemente",
                    "pago_id": pago_id,
                    "advertencia": "ESTA ACCIÓN NO SE PUEDE DESHACER",
                    "tipo": "hard_delete"
                }
            else:
                return {
                    "success": False,
                    "error": "No se pudo eliminar permanentemente el pago",
                    "pago_id": pago_id
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Error en eliminación permanente: {str(e)}",
                "pago_id": pago_id
            }