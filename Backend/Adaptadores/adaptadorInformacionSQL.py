from Dominio.repositorios.repositorioInformacion import RepositorioInformacion
from models.informacion import Informacion, InformacionStatsResponse, TipoInformacion
from models.cliente import Cliente
from sqlmodel import Session, select, func
from typing import List, Optional
from datetime import datetime, timedelta

class AdaptadorInformacionSQL(RepositorioInformacion):
    def __init__(self, session: Session):
        self.session = session

    def crear_informacion(self, informacion: Informacion) -> Informacion:
        # Verificar destinatario si es específico
        if informacion.destinatario_id:
            cliente = self.session.get(Cliente, informacion.destinatario_id)
            if not cliente:
                raise ValueError("Cliente destinatario no encontrado")
        
        self.session.add(informacion)
        self.session.commit()
        self.session.refresh(informacion)
        return informacion
    
    def listar_todas_las_informaciones(self):
        """Listar todas las informaciones, incluyendo inactivas"""
        with self.session as session:
            statement = select(Informacion)
            return session.exec(statement).all()
        
    def obtener_informacion_por_id(self, informacion_id: int) -> Optional[Informacion]:
        return self.session.get(Informacion, informacion_id)

    def listar_informaciones(self, activas: bool = True, tipo: Optional[TipoInformacion] = None, destinatario_id: Optional[str] = None) -> List[Informacion]:
        query = select(Informacion)
        
        if activas:
            query = query.where(Informacion.activa == True)
            query = query.where(
                (Informacion.fecha_expiracion.is_(None)) |
                (Informacion.fecha_expiracion > datetime.utcnow())
            )
        
        if tipo:
            query = query.where(Informacion.tipo == tipo)
        
        if destinatario_id:
            query = query.where(Informacion.destinatario_id == destinatario_id)
        else:
            query = query.where(Informacion.destinatario_id.is_(None))
        
        query = query.order_by(Informacion.prioridad.desc(), Informacion.fecha_publicacion.desc())
        
        return self.session.exec(query).all()

    def listar_informaciones_por_tipo(self, tipo: TipoInformacion, activas: bool = True) -> List[Informacion]:
        query = select(Informacion).where(Informacion.tipo == tipo)
        
        if activas:
            query = query.where(Informacion.activa == True)
            query = query.where(
                (Informacion.fecha_expiracion.is_(None)) |
                (Informacion.fecha_expiracion > datetime.utcnow())
            )
        
        query = query.order_by(Informacion.prioridad.desc(), Informacion.fecha_publicacion.desc())
        
        return self.session.exec(query).all()

    def listar_informaciones_por_cliente(self, cliente_dni: str) -> List[Informacion]:
        # Verificar que el cliente existe
        cliente = self.session.get(Cliente, cliente_dni)
        if not cliente:
            raise ValueError("Cliente no encontrado")
        
        query = select(Informacion).where(
            (Informacion.destinatario_id.is_(None)) |
            (Informacion.destinatario_id == cliente_dni)
        ).where(Informacion.activa == True).where(
            (Informacion.fecha_expiracion.is_(None)) |
            (Informacion.fecha_expiracion > datetime.utcnow())
        ).order_by(Informacion.prioridad.desc(), Informacion.fecha_publicacion.desc())
        
        return self.session.exec(query).all()

    def listar_alertas_activas(self) -> List[Informacion]:
        query = select(Informacion).where(
            Informacion.tipo == TipoInformacion.ALERTA,
            Informacion.activa == True,
            (Informacion.fecha_expiracion.is_(None)) |
            (Informacion.fecha_expiracion > datetime.utcnow())
        ).order_by(Informacion.prioridad.desc(), Informacion.fecha_publicacion.desc())
        
        return self.session.exec(query).all()

    def buscar_informaciones_por_palabra(self, palabra: str, activas: bool = True) -> List[Informacion]:
        query = select(Informacion).where(
            (Informacion.titulo.contains(palabra)) |
            (Informacion.contenido.contains(palabra))
        )
        
        if activas:
            query = query.where(Informacion.activa == True)
            query = query.where(
                (Informacion.fecha_expiracion.is_(None)) |
                (Informacion.fecha_expiracion > datetime.utcnow())
            )
        
        query = query.order_by(Informacion.prioridad.desc(), Informacion.fecha_publicacion.desc())
        
        return self.session.exec(query).all()

    def buscar_informaciones_por_fecha(self, fecha: datetime, activas: bool = True) -> List[Informacion]:
        inicio = datetime(fecha.year, fecha.month, fecha.day, 0, 0, 0)
        fin = datetime(fecha.year, fecha.month, fecha.day, 23, 59, 59)
        
        query = select(Informacion).where(Informacion.fecha_publicacion.between(inicio, fin))
        
        if activas:
            query = query.where(Informacion.activa == True)
            query = query.where(
                (Informacion.fecha_expiracion.is_(None)) |
                (Informacion.fecha_expiracion > datetime.utcnow())
            )
        
        query = query.order_by(Informacion.prioridad.desc(), Informacion.fecha_publicacion.desc())
        
        return self.session.exec(query).all()

    def actualizar_informacion(self, informacion_id: int, datos_actualizados: dict) -> Optional[Informacion]:
        informacion = self.obtener_informacion_por_id(informacion_id)
        if informacion:
            # Si se cambia el destinatario, verificar que existe
            if 'destinatario_id' in datos_actualizados and datos_actualizados['destinatario_id'] != informacion.destinatario_id:
                if datos_actualizados['destinatario_id']:
                    cliente = self.session.get(Cliente, datos_actualizados['destinatario_id'])
                    if not cliente:
                        raise ValueError("Cliente destinatario no encontrado")
            
            for key, value in datos_actualizados.items():
                setattr(informacion, key, value)
            
            self.session.add(informacion)
            self.session.commit()
            self.session.refresh(informacion)
        return informacion

    def eliminar_informacion(self, informacion_id: int) -> bool:
        informacion = self.obtener_informacion_por_id(informacion_id)
        if informacion:
            self.session.delete(informacion)
            self.session.commit()
            return True
        return False

    def activar_informacion(self, informacion_id: int):
        """Activar una información"""
        with self.session as session:
            informacion = session.get(Informacion, informacion_id)
            if informacion:
                informacion.activa = True
                session.add(informacion)
                session.commit()
                session.refresh(informacion)
            return informacion
        
    def desactivar_informacion(self, informacion_id: int):
        """Desactivar una información"""
        with self.session as session:
            informacion = session.get(Informacion, informacion_id)
            if informacion:
                informacion.activa = False
                session.add(informacion)
                session.commit()
                session.refresh(informacion)
            return informacion

    def obtener_estadisticas_avanzadas(self):
        """Obtener estadísticas avanzadas"""
        informaciones = self.listar_todas_las_informaciones()
        
        return {
            "total_informaciones": len(informaciones),
            "activas": len([i for i in informaciones if i.activa]),
            "inactivas": len([i for i in informaciones if not i.activa]),
            "por_tipo": self._calcular_por_tipo(informaciones)
        }

    # Método requerido por la interfaz del repositorio
    def obtener_estadisticas(self) -> dict:
        """Compatibilidad: delega a obtener_estadisticas_avanzadas para retornar un dict simple."""
        return self.obtener_estadisticas_avanzadas()
    
    def listar_informaciones_por_rango_fechas(self, fecha_inicio, fecha_fin):
        """Listar informaciones por rango de fechas"""
        with self.session as session:
            statement = select(Informacion).where(
                Informacion.fecha_creacion >= fecha_inicio,
                Informacion.fecha_creacion <= fecha_fin
            )
            return session.exec(statement).all()
    
    def obtener_informaciones_por_expiracion_proxima(self, dias_antes: int):
        """Obtener informaciones que expiran pronto"""
        from datetime import datetime, timedelta
        fecha_limite = datetime.now() + timedelta(days=dias_antes)
        
        with self.session as session:
            statement = select(Informacion).where(
                Informacion.fecha_expiracion <= fecha_limite,
                Informacion.fecha_expiracion >= datetime.now(),
                Informacion.activa == True
            )
            return session.exec(statement).all()
    
    def busqueda_avanzada(self, **filtros):
        """Búsqueda avanzada con múltiples parámetros"""
        with self.session as session:
            query = select(Informacion)
            
            if filtros.get('palabra_clave'):
                query = query.where(
                    Informacion.titulo.contains(filtros['palabra_clave']) |
                    Informacion.contenido.contains(filtros['palabra_clave'])
                )
            if filtros.get('tipo'):
                query = query.where(Informacion.tipo == filtros['tipo'])
            if filtros.get('destinatario_id'):
                query = query.where(Informacion.destinatario_id == filtros['destinatario_id'])
            if filtros.get('activa') is not None:
                query = query.where(Informacion.activa == filtros['activa'])
            if filtros.get('fecha_inicio'):
                query = query.where(Informacion.fecha_creacion >= filtros['fecha_inicio'])
            if filtros.get('fecha_fin'):
                query = query.where(Informacion.fecha_creacion <= filtros['fecha_fin'])
            
            return session.exec(query).all()
    
    def obtener_estadisticas_dashboard(self):
        """Estadísticas para dashboard"""
        stats = self.obtener_estadisticas_avanzadas()
        
        # Agregar más estadísticas para el dashboard
        ultima_semana = datetime.now() - timedelta(days=7)
        with self.session as session:
            nuevas_ultima_semana = session.exec(
                select(Informacion).where(Informacion.fecha_creacion >= ultima_semana)
            ).all()
        
        stats["nuevas_ultima_semana"] = len(nuevas_ultima_semana)
        stats["expiracion_proxima"] = len(self.obtener_informaciones_por_expiracion_proxima(7))
        
        return stats
    
    def obtener_ultimas_informaciones_creadas(self, limit: int = 10):
        """Obtener últimas informaciones creadas"""
        with self.session as session:
            statement = select(Informacion).order_by(Informacion.fecha_creacion.desc()).limit(limit)
            return session.exec(statement).all()
    
    def _calcular_por_tipo(self, informaciones):
        """Calcular estadísticas por tipo"""
        por_tipo = {}
        for info in informaciones:
            tipo = info.tipo.value
            if tipo not in por_tipo:
                por_tipo[tipo] = 0
            por_tipo[tipo] += 1
        return por_tipo