from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from typing import AsyncGenerator
from sqlalchemy import text
import sys
import os
from dotenv import load_dotenv  # ✅ Nuevo import

# ✅ Cargar variables de entorno desde el archivo .env
load_dotenv()

# Configurar path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Lifespan events
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    # Startup - crear tablas
    try:
        from database import engine
        from sqlmodel import SQLModel
        
        print("🔄 Creando tablas en la base de datos...")
        SQLModel.metadata.create_all(engine)
        print("✅ Tablas creadas exitosamente")
        
        # ✅ Verificar variables de entorno críticas
        required_vars = ["MERCADOPAGO_ACCESS_TOKEN"]
        for var in required_vars:
            if not os.getenv(var):
                print(f"⚠️  Advertencia: Variable {var} no está configurada")
            else:
                print(f"✅ Variable {var} cargada correctamente")
        
    except Exception as e:
        print(f"❌ Error creando tablas: {e}")
    
    yield
    
    # Shutdown
    print("🛑 Apagando aplicación")

# Crear aplicación FastAPI
app = FastAPI(
    title="Gimnasio API",
    version="1.0.0",
    lifespan=lifespan
)

# Configurar CORS con variables de entorno
frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")
DEBUG_MODE = os.getenv("DEBUG", "False").lower() in ("1", "true", "yes")

# En modo desarrollo permitimos todos los orígenes para facilitar pruebas desde Flutter web u otros dev-servers.
if DEBUG_MODE:
    allow_origins = ["*"]
else:
    allow_origins = [frontend_url, "http://localhost:3000", "http://127.0.0.1:3000"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# IMPORTAR routers reales DESPUÉS de crear la app
try:
    from routers.admin.admin_cliente_router import admin_cliente_router
    app.include_router(admin_cliente_router)
    print("✅ Router de clientes cargado")
except Exception as e:
    print(f"❌ Error cargando router de clientes: {e}")

try:
    from routers.admin.admin_clase_router import admin_clase_router
    app.include_router(admin_clase_router)
    print("✅ Router de clases cargado")
except Exception as e:
    print(f"❌ Error cargando router de clases: {e}")
    
try:
    from routers.admin.admin_inscripcion_router import admin_inscripcion_router
    app.include_router(admin_inscripcion_router)
    print("✅ Router de inscripciones cargado")
except Exception as e:
    print(f"❌ Error cargando router de inscripciones: {e}")

# Router de informaciones
try:
    from routers.admin.admin_informacion_router import admin_informacion_router
    app.include_router(admin_informacion_router)
    print("✅ Router de informaciones cargado")
except Exception as e:
    print(f"❌ Error cargando router de informaciones: {e}")

try:
    from routers.admin.admin_contenido_router import admin_contenido_router
    app.include_router(admin_contenido_router)
    print("✅ Router de contenidos cargado")
except Exception as e:
    print(f"❌ Error cargando router de contenidos: {e}")

# ✅ Router de Mercado Pago (corregido el nombre)
try:
    from routers.mercado_pago_router import mercado_pago_router  # ✅ Cambiado de admin_mercadopago_router a mercado_pago_router
    app.include_router(mercado_pago_router)
    print("✅ Router de Mercado Pago cargado")
except Exception as e:
    print(f"❌ Error cargando router de Mercado Pago: {e}")

try:
    from routers.admin.admin_transaccion_router import admin_transaccion_router
    app.include_router(admin_transaccion_router)
    print("✅ Router de transacciones cargado")
except Exception as e:
    print(f"❌ Error cargando router de transacciones: {e}")

try:
    from routers.admin.admin_pago_router import admin_pago_router  # ✅ Agregar router de pagos
    app.include_router(admin_pago_router)
    print("✅ Router administrativo de pagos cargado")
except Exception as e:
    print(f"❌ Error cargando router administrativo de pagos: {e}")

# ✅ También agregar para servir archivos estáticos
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")    
    
# Health check endpoint
@app.get("/")
async def root():
    return {
        "message": "Gimnasio API funcionando correctamente", 
        "version": "1.0.0",
        "environment": "development" if os.getenv("DEBUG") else "production"
    }

@app.get("/health")
async def health_check():
    try:
        from database import engine
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        
        # ✅ Verificar variables críticas
        mp_token = os.getenv("MERCADOPAGO_ACCESS_TOKEN")
        status = {
            "status": "OK", 
            "database": "connected",
            "mercado_pago": "configured" if mp_token else "not_configured",
            "frontend_url": os.getenv("FRONTEND_URL", "not_set"),
            "backend_url": os.getenv("BACKEND_URL", "not_set")
        }
        return status
    except Exception as e:
        return {"status": "ERROR", "database": "disconnected", "error": str(e)}

# ✅ Endpoint para verificar configuración
@app.get("/config")
async def show_config():
    """Mostrar configuración actual (sin valores sensibles)"""
    return {
        "frontend_url": os.getenv("FRONTEND_URL"),
        "backend_url": os.getenv("BACKEND_URL"),
        "debug_mode": os.getenv("DEBUG", "False"),
        "mercado_pago_configured": "Yes" if os.getenv("MERCADOPAGO_ACCESS_TOKEN") else "No"
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)