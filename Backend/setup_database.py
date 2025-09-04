import mysql.connector
from database import engine

def setup_database():
    try:
        print("🔧 Configurando base de datos Gimnasio...")
        
        # Primero conectar para crear la base de datos si no existe
        connection = mysql.connector.connect(
            host="localhost",
            port=3308,
            user="root",
            password="123456",
            auth_plugin='mysql_native_password'
        )
        
        cursor = connection.cursor()
        
        # Crear base de datos si no existe
        cursor.execute("CREATE DATABASE IF NOT EXISTS gimnasio")
        print("✅ Base de datos 'gimnasio' creada/verificada")
        
        # Mostrar todas las bases de datos
        cursor.execute("SHOW DATABASES")
        databases = [db[0] for db in cursor.fetchall()]
        print(f"📊 Bases de datos disponibles: {databases}")
        
        cursor.close()
        connection.close()
        
        # Ahora probar con SQLModel
        print("🔄 Probando conexión con SQLModel...")
        with engine.connect() as conn:
            # Crear las tablas
            from sqlmodel import SQLModel
            from models.cliente import Cliente
            SQLModel.metadata.create_all(engine)
            print("✅ Tablas creadas exitosamente")
            
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    setup_database()