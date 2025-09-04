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