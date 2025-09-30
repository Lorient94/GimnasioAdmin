from datetime import datetime, timedelta
from Dominio.repositorios.repositorioCliente import RepositorioCliente
from models.cliente import Cliente
from sqlmodel import Session, select, func
from typing import Optional, List

class AdaptadorClienteSQL(RepositorioCliente):
    def __init__(self, session: Session):
        self.session = session

    def crear_usuario(self, cliente: Cliente) -> Cliente:
        print(f'🌱 Guardando usuario en DB: {cliente}')

        cliente.password = cliente.dni
        self.session.add(cliente)
        self.session.commit()
        self.session.refresh(cliente)
        print(f'🌱 Usuario guardado en DB: {cliente}')

        return cliente
    
    def iniciar_sesion(self, correo: str, password: str) -> Optional[Cliente]:
        print(f"🔐 Adaptador: Buscando usuario con correo: {correo}")
        
        statement = select(Cliente).where(Cliente.correo == correo)
        resultado = self.session.exec(statement).first()
        
        if resultado:
            print(f"🔐 Adaptador: Usuario encontrado: {resultado.nombre}")
            print(f"🔐 Adaptador: Password en BD: {resultado.password}")
            print(f"🔐 Adaptador: Password proporcionado: {password}")
            print(f"🔐 Adaptador: Coinciden?: {resultado.password == password}")
            
            if resultado.password == password:
                print("✅ Adaptador: Contraseña válida")
                return resultado
            else:
                print("❌ Adaptador: Contraseña incorrecta")
        else:
            print("❌ Adaptador: Usuario no encontrado")
        
        return None

    def modificar_usuario(self, dni: str, datos_actualizados: dict) -> Optional[Cliente]:
        cliente = self.consultar_usuario(dni)
        if cliente:
            # SOLO actualizar campos que existen en el modelo Cliente
            campos_validos = ['nombre', 'telefono', 'correo', 'ciudad', 'genero', 'activo', 'password']
            
            for key, value in datos_actualizados.items():
                if key in campos_validos and value is not None:  # ← Solo actualizar campos válidos
                    setattr(cliente, key, value)
                    print(f"✅ Actualizando campo {key}: {value}")
                else:
                    print(f"⚠️  Ignorando campo inválido: {key}")
            
            self.session.add(cliente)
            self.session.commit()
            self.session.refresh(cliente)
        return cliente

    def consultar_usuario(self, dni: str) -> Optional[Cliente]:
        statement = select(Cliente).where(Cliente.dni == dni)
        return self.session.exec(statement).first()

    def consultar_usuario_por_id(self, id: int) -> Optional[Cliente]:
        return self.session.get(Cliente, id)

    def consultar_usuario_por_correo(self, correo: str) -> Optional[Cliente]:
        statement = select(Cliente).where(Cliente.correo == correo)
        return self.session.exec(statement).first()

    def listar_usuarios(self, activos: bool = True) -> List[Cliente]:
        query = select(Cliente)
        if activos:
            query = query.where(Cliente.activo == True)
        return self.session.exec(query).all()

    def eliminar_usuario(self, dni: str) -> bool:
        cliente = self.consultar_usuario(dni)
        if cliente:
            cliente.activo = False
            self.session.add(cliente)
            self.session.commit()
            return True
        return False

    def autenticar_correo(self, correo: str) -> bool:
        return self.consultar_usuario_por_correo(correo) is not None

    def contar_usuarios(self) -> int:
        statement = select(func.count(Cliente.id))
        return self.session.exec(statement).one()
    def listar_todos_los_usuarios(self) -> List[Cliente]:
        """Listar todos los usuarios, incluyendo inactivos"""
        with self.session as session:
            statement = select(Cliente)
            resultados = session.exec(statement).all()
            return resultados
    
    def consultar_usuario_completo(self, dni: str) -> Optional[Cliente]:
        """Obtener usuario con información completa"""
        return self.consultar_usuario(dni)
    
    def activar_usuario(self, cliente_id: int) -> Optional[Cliente]:
        """Activar un usuario"""
        with self.session as session:
            cliente = session.get(Cliente, cliente_id)
            if cliente:
                cliente.activo = True
                session.add(cliente)
                session.commit()
                session.refresh(cliente)
            return cliente
    
    def desactivar_usuario(self, cliente_id: int) -> Optional[Cliente]:
        """Desactivar un usuario"""
        with self.session as session:
            cliente = session.get(Cliente, cliente_id)
            if cliente:
                cliente.activo = False
                session.add(cliente)
                session.commit()
                session.refresh(cliente)
            return cliente
    
    def actualizar_membresia(self, cliente_id: int, nuevo_estado: str, fecha_expiracion=None) -> Optional[Cliente]:
        """Actualizar estado de membresía"""
        with self.session as session:
            cliente = session.get(Cliente, cliente_id)
            if cliente:
                cliente.estado_membresia = nuevo_estado
                if fecha_expiracion:
                    cliente.fecha_expiracion_membresia = fecha_expiracion
                session.add(cliente)
                session.commit()
                session.refresh(cliente)
            return cliente
    
    def eliminar_usuario_permanentemente(self, cliente_id: int) -> bool:
        """Eliminar usuario permanentemente"""
        with self.session as session:
            cliente = session.get(Cliente, cliente_id)
            if cliente:
                session.delete(cliente)
                session.commit()
                return True
            return False
    
    def obtener_estadisticas_clientes(self) -> dict:
        """Obtener estadísticas de clientes"""
        with self.session as session:
            total_clientes = session.exec(select(Cliente)).all()
            activos = [c for c in total_clientes if c.activo]
            inactivos = [c for c in total_clientes if not c.activo]
            
            return {
                "total_clientes": len(total_clientes),
                "clientes_activos": len(activos),
                "clientes_inactivos": len(inactivos),
                "porcentaje_activos": round((len(activos) / len(total_clientes) * 100), 2) if total_clientes else 0
            }
    
    def busqueda_avanzada_clientes(self, **filtros) -> List[Cliente]:
        """Búsqueda avanzada de clientes"""
        with self.session as session:
            query = select(Cliente)
            
            if filtros.get('nombre'):
                query = query.where(Cliente.nombre.contains(filtros['nombre']))
            if filtros.get('correo'):
                query = query.where(Cliente.correo.contains(filtros['correo']))
            if filtros.get('dni'):
                query = query.where(Cliente.dni.contains(filtros['dni']))
            if filtros.get('estado_membresia'):
                query = query.where(Cliente.estado_membresia == filtros['estado_membresia'])
            if filtros.get('activo') is not None:
                query = query.where(Cliente.activo == filtros['activo'])
            if filtros.get('fecha_registro_inicio'):
                query = query.where(Cliente.fecha_registro >= filtros['fecha_registro_inicio'])
            if filtros.get('fecha_registro_fin'):
                query = query.where(Cliente.fecha_registro <= filtros['fecha_registro_fin'])
            
            return session.exec(query).all()
    
    def obtener_membresias_por_expiracion_proxima(self, dias_antes: int) -> List[Cliente]:
        """Obtener membresías que expiran pronto"""
        from datetime import datetime, timedelta
        fecha_limite = datetime.now() + timedelta(days=dias_antes)
        
        with self.session as session:
            query = select(Cliente).where(
                Cliente.fecha_expiracion_membresia <= fecha_limite,
                Cliente.fecha_expiracion_membresia >= datetime.now(),
                Cliente.activo == True
            )
            return session.exec(query).all()
    
    def obtener_ultimos_clientes_registrados(self, limit: int = 10) -> List[Cliente]:
        """Obtener últimos clientes registrados"""
        with self.session as session:
            query = select(Cliente).order_by(Cliente.fecha_registro.desc()).limit(limit)
            return session.exec(query).all()
    
    def obtener_estadisticas_dashboard(self) -> dict:
        """Estadísticas para dashboard"""
        stats = self.obtener_estadisticas_clientes()
        
        # Agregar más estadísticas
        ultima_semana = datetime.now() - timedelta(days=7)
        with self.session as session:
            nuevos_ultima_semana = session.exec(
                select(Cliente).where(Cliente.fecha_registro >= ultima_semana)
            ).all()
        
        stats["nuevos_ultima_semana"] = len(nuevos_ultima_semana)
        stats["membresias_expiracion_proxima"] = len(self.obtener_membresias_por_expiracion_proxima(7))
        
        return stats
    
    def verificar_correo_existente(self, correo: str, excluir_id: int = None) -> bool:
        """Verificar si un correo existe, excluyendo un ID específico"""
        with self.session as session:
            query = select(Cliente).where(Cliente.correo == correo)
            if excluir_id:
                query = query.where(Cliente.id != excluir_id)
            cliente = session.exec(query).first()
            return cliente is not None
    
    def obtener_inscripciones_activas(self, cliente_id: int) -> List:
        """Obtener inscripciones activas de un cliente"""
        # Esto depende de tu modelo de inscripciones
        # Retorna una lista vacía por ahora
        return []