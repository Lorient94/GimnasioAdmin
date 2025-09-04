from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import AsyncGenerator
import sys
import os


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

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# IMPORTAR routers reales DESPUÉS de crear la app
try:
    from routers.cliente_router import cliente_router
    app.include_router(cliente_router)
    print("✅ Router de clientes cargado")
except Exception as e:
    print(f"❌ Error cargando router de clientes: {e}")

try:
    from routers.clase_router import clase_router
    app.include_router(clase_router)
    print("✅ Router de clases cargado")
except Exception as e:
    print(f"❌ Error cargando router de clases: {e}")
    
try:
    from routers.inscripcion_router import inscripcion_router  # Asegúrate de que el nombre del archivo sea correcto
    app.include_router(inscripcion_router)
    print("✅ Router de inscripciones cargado")
except Exception as e:
    print(f"❌ Error cargando router de inscripciones: {e}")

# Router de informaciones
try:
    from routers.informacion_router import informacion_router
    app.include_router(informacion_router)
    print("✅ Router de informaciones cargado")
except Exception as e:
    print(f"❌ Error cargando router de informaciones: {e}")

try:
    from routers.contenido_router import contenido_router
    app.include_router(contenido_router)
    print("✅ Router de contenidos cargado")
except Exception as e:
    print(f"❌ Error cargando router de contenidos: {e}")

# Health check endpoint
@app.get("/")
async def root():
    return {"message": "Gimnasio API funcionando correctamente"}

@app.get("/health")
async def health_check():
    try:
        from database import engine
        with engine.connect() as conn:
            conn.execute("SELECT 1")
        return {"status": "OK", "database": "connected"}
    except Exception as e:
        return {"status": "ERROR", "database": "disconnected", "error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)