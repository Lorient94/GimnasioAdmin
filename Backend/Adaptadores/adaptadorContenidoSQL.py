from fastapi import requests
from Dominio.repositorios.repositorioContenido import RepositorioContenido
from models.contenido import Contenido, ContenidoCategoriaResponse
from sqlmodel import Session, select, func
from typing import List, Optional
from datetime import datetime

class AdaptadorContenidoSQL(RepositorioContenido):
    def __init__(self, session: Session):
        self.session = session

    def crear_contenido(self, contenido: Contenido) -> Contenido:
        self.session.add(contenido)
        self.session.commit()
        self.session.refresh(contenido)
        return contenido

    def obtener_contenido_por_id(self, contenido_id: int) -> Optional[Contenido]:
        return self.session.get(Contenido, contenido_id)

    def listar_contenidos(self, activos: bool = True, categoria: Optional[str] = None) -> List[Contenido]:
        query = select(Contenido)
        
        if activos:
            query = query.where(Contenido.activo == True)
        
        if categoria:
            query = query.where(Contenido.categoria == categoria)
        
        query = query.order_by(Contenido.fecha_creacion.desc())
        
        return self.session.exec(query).all()

    def listar_contenidos_por_categoria(self, categoria: str, activos: bool = True) -> List[Contenido]:
        query = select(Contenido).where(Contenido.categoria == categoria)
        
        if activos:
            query = query.where(Contenido.activo == True)
        
        query = query.order_by(Contenido.fecha_creacion.desc())
        
        return self.session.exec(query).all()

    def listar_categorias(self) -> List[str]:
        statement = select(Contenido.categoria).distinct().where(Contenido.activo == True)
        return self.session.exec(statement).all()

    def listar_contenidos_agrupados_por_categoria(self) -> List[ContenidoCategoriaResponse]:
        categorias = self.listar_categorias()
        
        resultado = []
        for categoria in categorias:
            contenidos = self.listar_contenidos_por_categoria(categoria, activos=True)
            
            resultado.append(ContenidoCategoriaResponse(
                categoria=categoria,
                cantidad=len(contenidos),
                contenidos=contenidos
            ))
        
        return resultado

    def buscar_contenidos(self, palabra_clave: str, activos: bool = True) -> List[Contenido]:
        query = select(Contenido).where(
            (Contenido.titulo.contains(palabra_clave)) |
            (Contenido.descripcion.contains(palabra_clave))
        )
        
        if activos:
            query = query.where(Contenido.activo == True)
        
        query = query.order_by(Contenido.fecha_creacion.desc())
        
        return self.session.exec(query).all()

    
    def buscar_contenidos_por_fecha(self, fecha_str: str, activos: bool = True) -> List[Contenido]:
        try:
            fecha = datetime.strptime(fecha_str, "%Y-%m-%d")
            inicio = datetime(fecha.year, fecha.month, fecha.day, 0, 0, 0)
            fin = datetime(fecha.year, fecha.month, fecha.day, 23, 59, 59)
            
            query = select(Contenido).where(Contenido.fecha_creacion.between(inicio, fin))
            
            if activos:
                query = query.where(Contenido.activo == True)
            
            query = query.order_by(Contenido.fecha_creacion.desc())
            
            return self.session.exec(query).all()
        except ValueError:
            return [] 

    def actualizar_contenido(self, contenido_id: int, datos_actualizados: dict) -> Optional[Contenido]:
        contenido = self.obtener_contenido_por_id(contenido_id)
        if contenido:
            for key, value in datos_actualizados.items():
                setattr(contenido, key, value)
            
            # Actualizar fecha de modificación
            contenido.fecha_actualizacion = datetime.utcnow()
            
            self.session.add(contenido)
            self.session.commit()
            self.session.refresh(contenido)
        return contenido

    def eliminar_contenido(self, contenido_id: int) -> bool:
        contenido = self.obtener_contenido_por_id(contenido_id)
        if contenido:
            contenido.activo = False
            contenido.fecha_actualizacion = datetime.utcnow()
            self.session.add(contenido)
            self.session.commit()
            return True
        return False

    def activar_contenido(self, contenido_id: int) -> Optional[Contenido]:
        contenido = self.obtener_contenido_por_id(contenido_id)
        if contenido:
            contenido.activo = True
            contenido.fecha_actualizacion = datetime.utcnow()
            self.session.add(contenido)
            self.session.commit()
            self.session.refresh(contenido)
        return contenido

    def descargar_contenido(self, contenido_id: int) -> Optional[bytes]:
        contenido = self.obtener_contenido_por_id(contenido_id)
        if contenido and contenido.url:
            try:
                respuesta = requests.get(contenido.url)
                if respuesta.status_code == 200:
                    return respuesta.content
            except Exception as e:
                print(f"Error al descargar contenido: {e}")
        return None