# Adaptadores/adaptadorInscripcionSQL.py
from sqlmodel import Session, select, join, func
from typing import List, Optional, Dict, Any
from datetime import datetime
from Dominio.repositorios.repositorioInscripciones import RepositorioInscripciones
from models.inscripcion import Inscripcion, InscripcionRead, EstadoInscripcion
from models.cliente import Cliente
from models.clase import Clase

class AdaptadorInscripcionesSQL(RepositorioInscripciones):
    def __init__(self, session: Session):
        self.session = session

    # ========== MÉTODOS BÁSICOS CRUD ==========
    
    def crear_inscripcion(self, inscripcion: Inscripcion) -> Inscripcion:
        """Crear una nueva inscripción"""
        try:
            print(f"DEBUG: Creando inscripción para cliente {inscripcion.cliente_dni} en clase {inscripcion.clase_id}")
            self.session.add(inscripcion)
            self.session.commit()
            self.session.refresh(inscripcion)
            print(f"DEBUG: Inscripción {inscripcion.id} creada exitosamente")
            return inscripcion
        except Exception as e:
            self.session.rollback()
            print(f"ERROR al crear inscripción: {e}")
            raise

    def consultar_inscripcion(self, inscripcion_id: int) -> Optional[Inscripcion]:
        """Obtener una inscripción básica por ID"""
        return self.session.get(Inscripcion, inscripcion_id)

    def actualizar_inscripcion(self, inscripcion_id: int, datos_actualizacion: Dict[str, Any]) -> Optional[Inscripcion]:
        """Actualizar una inscripción existente"""
        try:
            print(f"DEBUG: Actualizando inscripción ID {inscripcion_id} con datos: {datos_actualizacion}")
            inscripcion = self.session.get(Inscripcion, inscripcion_id)
            if not inscripcion:
                print(f"DEBUG: Inscripción {inscripcion_id} no encontrada")
                return None
            
            for key, value in datos_actualizacion.items():
                if hasattr(inscripcion, key):
                    setattr(inscripcion, key, value)
            
            self.session.add(inscripcion)
            self.session.commit()
            self.session.refresh(inscripcion)
            print(f"DEBUG: Inscripción {inscripcion_id} actualizada exitosamente")
            return inscripcion
        except Exception as e:
            self.session.rollback()
            print(f"ERROR al actualizar inscripción: {e}")
            return None

    def eliminar_inscripcion(self, inscripcion_id: int) -> bool:
        """Eliminar una inscripción (soft delete)"""
        try:
            inscripcion = self.session.get(Inscripcion, inscripcion_id)
            if inscripcion:
                # Soft delete - marcar como cancelada
                inscripcion.estado = EstadoInscripcion.CANCELADO
                inscripcion.fecha_cancelacion = datetime.utcnow()
                inscripcion.motivo_cancelacion = "Eliminada por administrador"
                self.session.add(inscripcion)
                self.session.commit()
                return True
            return False
        except Exception as e:
            self.session.rollback()
            print(f"ERROR al eliminar inscripción: {e}")
            return False

    # ========== MÉTODOS DE CONSULTA AVANZADA ==========

    def listar_todas_las_inscripciones(self) -> List[InscripcionRead]:
        """Obtener todas las inscripciones con datos relacionados"""
        try:
            statement = select(
                Inscripcion,
                Cliente.nombre,
                Cliente.correo,
                Clase.nombre,
                Clase.instructor
            ).select_from(
                join(Inscripcion, Cliente, Inscripcion.cliente_dni == Cliente.dni)
                .join(Clase, Inscripcion.clase_id == Clase.id)
            )
            
            results = self.session.exec(statement)
            inscripciones_completas = []
            
            for inscripcion, cliente_nombre, cliente_correo, clase_nombre, clase_instructor in results:
                inscripcion_read = InscripcionRead(
                    id=inscripcion.id,
                    cliente_dni=inscripcion.cliente_dni,
                    clase_id=inscripcion.clase_id,
                    estado=inscripcion.estado,
                    pagado=inscripcion.pagado,
                    fecha_inscripcion=inscripcion.fecha_inscripcion,
                    fecha_cancelacion=inscripcion.fecha_cancelacion,
                    motivo_cancelacion=inscripcion.motivo_cancelacion,
                    transaccion_id=inscripcion.transaccion_id,
                    nombre_cliente=cliente_nombre,
                    email_cliente=cliente_correo,
                    clase_nombre=clase_nombre,
                    clase_instructor=clase_instructor,
                    clase_precio=0.0  # Temporal, ya que Clase no tiene precio
                )
                inscripciones_completas.append(inscripcion_read)
            
            print(f"✅ Adaptador: Se procesaron {len(inscripciones_completas)} inscripciones")
            return inscripciones_completas
            
        except Exception as e:
            print(f"❌ Error en listar_todas_las_inscripciones: {e}")
            return self._fallback_sin_relaciones()

    def consultar_inscripcion_completa(self, inscripcion_id: int) -> Optional[InscripcionRead]:
        """Obtener una inscripción con todos los datos relacionados"""
        try:
            statement = select(
                Inscripcion,
                Cliente.nombre,
                Cliente.correo,
                Clase.nombre,
                Clase.instructor
            ).select_from(
                join(Inscripcion, Cliente, Inscripcion.cliente_dni == Cliente.dni)
                .join(Clase, Inscripcion.clase_id == Clase.id)
            ).where(Inscripcion.id == inscripcion_id)
            
            result = self.session.exec(statement).first()
            
            if not result:
                return None
                
            inscripcion, cliente_nombre, cliente_correo, clase_nombre, clase_instructor = result
            
            return InscripcionRead(
                id=inscripcion.id,
                cliente_dni=inscripcion.cliente_dni,
                clase_id=inscripcion.clase_id,
                estado=inscripcion.estado,
                pagado=inscripcion.pagado,
                fecha_inscripcion=inscripcion.fecha_inscripcion,
                fecha_cancelacion=inscripcion.fecha_cancelacion,
                motivo_cancelacion=inscripcion.motivo_cancelacion,
                transaccion_id=inscripcion.transaccion_id,
                nombre_cliente=cliente_nombre,
                email_cliente=cliente_correo,
                clase_nombre=clase_nombre,
                clase_instructor=clase_instructor,
                clase_precio=0.0
            )
            
        except Exception as e:
            print(f"❌ Error en consultar_inscripcion_completa: {e}")
            return None

    # ========== MÉTODOS DE GESTIÓN DE ESTADO ==========

    def cancelar_inscripcion(self, inscripcion_id: int, motivo: str) -> bool:
        """Cancelar una inscripción"""
        try:
            inscripcion = self.session.get(Inscripcion, inscripcion_id)
            if inscripcion:
                inscripcion.estado = EstadoInscripcion.CANCELADO
                inscripcion.fecha_cancelacion = datetime.utcnow()
                inscripcion.motivo_cancelacion = motivo
                self.session.add(inscripcion)
                self.session.commit()
                return True
            return False
        except Exception as e:
            self.session.rollback()
            print(f"ERROR al cancelar inscripción: {e}")
            return False

    def reactivar_inscripcion(self, inscripcion_id: int) -> Optional[Inscripcion]:
        """Reactivar una inscripción cancelada"""
        try:
            inscripcion = self.session.get(Inscripcion, inscripcion_id)
            if inscripcion and inscripcion.estado == EstadoInscripcion.CANCELADO:
                inscripcion.estado = EstadoInscripcion.ACTIVO
                inscripcion.fecha_cancelacion = None
                inscripcion.motivo_cancelacion = None
                self.session.add(inscripcion)
                self.session.commit()
                self.session.refresh(inscripcion)
                return inscripcion
            return None
        except Exception as e:
            self.session.rollback()
            print(f"ERROR al reactivar inscripción: {e}")
            return None

    def completar_inscripcion(self, inscripcion_id: int) -> bool:
        """Marcar una inscripción como completada"""
        try:
            inscripcion = self.session.get(Inscripcion, inscripcion_id)
            if inscripcion:
                inscripcion.estado = EstadoInscripcion.COMPLETADO
                self.session.add(inscripcion)
                self.session.commit()
                return True
            return False
        except Exception as e:
            self.session.rollback()
            print(f"ERROR al completar inscripción: {e}")
            return False

    def marcar_pagado(self, inscripcion_id: int) -> bool:
        """Marcar una inscripción como pagada"""
        try:
            inscripcion = self.session.get(Inscripcion, inscripcion_id)
            if inscripcion:
                inscripcion.pagado = True
                self.session.add(inscripcion)
                self.session.commit()
                return True
            return False
        except Exception as e:
            self.session.rollback()
            print(f"ERROR al marcar como pagado: {e}")
            return False

    # ========== MÉTODOS DE CONSULTA ESPECÍFICA ==========

    def ver_inscripciones_cliente(self, cliente_dni: str) -> List[Inscripcion]:
        """Obtener todas las inscripciones de un cliente"""
        try:
            statement = select(Inscripcion).where(Inscripcion.cliente_dni == cliente_dni)
            return list(self.session.exec(statement))
        except Exception as e:
            print(f"ERROR al obtener inscripciones del cliente: {e}")
            return []

    def ver_inscripciones_clase(self, clase_id: int) -> List[Inscripcion]:
        """Obtener todas las inscripciones de una clase"""
        try:
            statement = select(Inscripcion).where(Inscripcion.clase_id == clase_id)
            return list(self.session.exec(statement))
        except Exception as e:
            print(f"ERROR al obtener inscripciones de la clase: {e}")
            return []

    # ========== MÉTODOS DE ESTADÍSTICAS ==========

    def obtener_estadisticas(self) -> Dict[str, Any]:
        """Obtener estadísticas generales de inscripciones"""
        try:
            total = self.session.exec(select(func.count(Inscripcion.id))).one()
            activas = self.session.exec(
                select(func.count(Inscripcion.id))
                .where(Inscripcion.estado == EstadoInscripcion.ACTIVO)
            ).one()
            canceladas = self.session.exec(
                select(func.count(Inscripcion.id))
                .where(Inscripcion.estado == EstadoInscripcion.CANCELADO)
            ).one()
            completadas = self.session.exec(
                select(func.count(Inscripcion.id))
                .where(Inscripcion.estado == EstadoInscripcion.COMPLETADO)
            ).one()
            pendientes = self.session.exec(
                select(func.count(Inscripcion.id))
                .where(Inscripcion.estado == EstadoInscripcion.PENDIENTE)
            ).one()
            
            return {
                "total_inscripciones": total,
                "activas": activas,
                "canceladas": canceladas,
                "completadas": completadas,
                "pendientes": pendientes
            }
        except Exception as e:
            print(f"ERROR al obtener estadísticas: {e}")
            return {
                "total_inscripciones": 0,
                "activas": 0,
                "canceladas": 0,
                "completadas": 0,
                "pendientes": 0
            }

    # ========== MÉTODOS AUXILIARES ==========

    def _fallback_sin_relaciones(self) -> List[InscripcionRead]:
        """Fallback cuando fallan los joins"""
        try:
            inscripciones = self.session.exec(select(Inscripcion)).all()
            resultado = []
            
            for insc in inscripciones:
                # Obtener datos básicos sin relaciones
                resultado.append(InscripcionRead(
                    id=insc.id,
                    cliente_dni=insc.cliente_dni,
                    clase_id=insc.clase_id,
                    estado=insc.estado,
                    pagado=insc.pagado,
                    fecha_inscripcion=insc.fecha_inscripcion,
                    fecha_cancelacion=insc.fecha_cancelacion,
                    motivo_cancelacion=insc.motivo_cancelacion,
                    transaccion_id=insc.transaccion_id,
                    nombre_cliente=f"Cliente {insc.cliente_dni}",
                    email_cliente="email@temporal.com",
                    clase_nombre=f"Clase {insc.clase_id}",
                    clase_instructor="Instructor",
                    clase_precio=0.0
                ))
            
            return resultado
        except Exception as e:
            print(f"ERROR en fallback: {e}")
            return []

    # ========== MÉTODOS ADICIONALES PARA REPORTES ==========

    def obtener_clases_populares(self) -> List[dict]:
        """Obtener clases más populares"""
        try:
            inscripciones = self.listar_todas_las_inscripciones()
            clases_count = {}
            
            for insc in inscripciones:
                clase_id = insc.clase_id
                if clase_id not in clases_count:
                    clases_count[clase_id] = {
                        'clase_id': clase_id,
                        'nombre': insc.clase_nombre,
                        'cantidad': 0
                    }
                clases_count[clase_id]['cantidad'] += 1
            
            return sorted(clases_count.values(), key=lambda x: x['cantidad'], reverse=True)[:10]
        except:
            return []

    def obtener_clientes_activos(self) -> List[dict]:
        """Obtener clientes más activos"""
        try:
            inscripciones = self.listar_todas_las_inscripciones()
            clientes_count = {}
            
            for insc in inscripciones:
                cliente_dni = insc.cliente_dni
                if cliente_dni not in clientes_count:
                    clientes_count[cliente_dni] = {
                        'cliente_dni': cliente_dni,
                        'nombre': insc.nombre_cliente,
                        'cantidad': 0
                    }
                clientes_count[cliente_dni]['cantidad'] += 1
            
            return sorted(clientes_count.values(), key=lambda x: x['cantidad'], reverse=True)[:10]
        except:
            return []

    def obtener_clases_cupo_critico(self, porcentaje_alerta: int) -> List[dict]:
        """Obtener clases con cupos críticos"""
        # Implementación básica - necesitarías más lógica
        return []