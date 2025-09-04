from Dominio.repositorios.repositorioInformacion import RepositorioInformacion
from models.informacion import Informacion, InformacionStatsResponse, TipoInformacion
from models.cliente import Cliente
from sqlmodel import Session, select, func
from typing import List, Optional
from datetime import datetime

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

    def activar_informacion(self, informacion_id: int) -> Optional[Informacion]:
        informacion = self.obtener_informacion_por_id(informacion_id)
        if informacion:
            informacion.activa = True
            self.session.add(informacion)
            self.session.commit()
            self.session.refresh(informacion)
        return informacion

    def desactivar_informacion(self, informacion_id: int) -> Optional[Informacion]:
        informacion = self.obtener_informacion_por_id(informacion_id)
        if informacion:
            informacion.activa = False
            self.session.add(informacion)
            self.session.commit()
            self.session.refresh(informacion)
        return informacion

    def obtener_estadisticas(self) -> InformacionStatsResponse:
        total = self.session.exec(select(func.count(Informacion.id))).one()
        activas = self.session.exec(select(func.count(Informacion.id)).where(Informacion.activa == True)).one()
        permanentes = self.session.exec(select(func.count(Informacion.id)).where(Informacion.tipo == TipoInformacion.PERMANENTE)).one()
        alertas = self.session.exec(select(func.count(Informacion.id)).where(Informacion.tipo == TipoInformacion.ALERTA)).one()
        noticias = self.session.exec(select(func.count(Informacion.id)).where(Informacion.tipo == TipoInformacion.NOTICIA)).one()
        promociones = self.session.exec(select(func.count(Informacion.id)).where(Informacion.tipo == TipoInformacion.PROMOCION)).one()
        
        return InformacionStatsResponse(
            total=total,
            activas=activas,
            permanentes=permanentes,
            alertas=alertas,
            noticias=noticias,
            promociones=promociones
        )