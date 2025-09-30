# routers/admin_contenido_router.py
from fastapi import APIRouter, HTTPException, status, Depends, Query, UploadFile, File
from sqlmodel import Session
from typing import List, Optional
import os
from datetime import datetime

from database import get_session
from models.contenido import Contenido, ContenidoCreate, ContenidoRead, ContenidoUpdate, ContenidoCategoriaResponse
from Adaptadores.adaptadorContenidoSQL import AdaptadorContenidoSQL
from Dominio.repositorios.repositorioContenido import RepositorioContenido

# Importar casos de uso
from Casos_de_uso.Contenido.crear_contenido import CrearContenidoCase
from Casos_de_uso.Contenido.modificar_contenido import ModificarContenidoCase
from Casos_de_uso.Contenido.eliminar_contenido import EliminarContenidoCase

admin_contenido_router = APIRouter(prefix="/api/admin/contenidos", tags=["admin-contenidos"])

# Configuración para uploads
UPLOAD_DIR = "uploads/contenidos"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def get_contenido_repository(session: Session = Depends(get_session)) -> RepositorioContenido:
    return AdaptadorContenidoSQL(session)

@admin_contenido_router.get("/", response_model=List[ContenidoRead])
def listar_todos_los_contenidos(
    solo_activos: bool = Query(False, description="Filtrar solo contenidos activos"),
    categoria: Optional[str] = Query(None, description="Filtrar por categoría"),
    tipo_archivo: Optional[str] = Query(None, description="Filtrar por tipo de archivo"),
    palabra_clave: Optional[str] = Query(None, description="Buscar por palabra clave"),
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener todos los contenidos (incluyendo inactivos) - Solo para administradores"""
    if solo_activos:
        contenidos = repository.listar_contenidos(activos=True, categoria=categoria)
    else:
        # Para administradores, mostrar todos los contenidos
        contenidos = repository.listar_todos_los_contenidos(categoria=categoria)
    
    # Aplicar filtros adicionales
    if tipo_archivo:
        contenidos = [c for c in contenidos if c.tipo_archivo and tipo_archivo.lower() in c.tipo_archivo.lower()]
    
    if palabra_clave:
        contenidos = [c for c in contenidos if palabra_clave.lower() in c.titulo.lower() or 
                    (c.descripcion and palabra_clave.lower() in c.descripcion.lower())]
    
    return contenidos

@admin_contenido_router.get("/{contenido_id}", response_model=ContenidoRead)
def obtener_contenido_detallado(
    contenido_id: int, 
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener un contenido con todos los detalles - Solo para administradores"""
    contenido = repository.obtener_contenido_por_id(contenido_id)
    if not contenido:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    return contenido

@admin_contenido_router.post("/", response_model=ContenidoRead, status_code=status.HTTP_201_CREATED)
def crear_contenido_admin(
    contenido_data: ContenidoCreate, 
    session: Session = Depends(get_session)
):
    """Crear un nuevo contenido - Solo para administradores"""
    caso_uso = CrearContenidoCase(session)
    
    try:
        contenido_creado = caso_uso.ejecutar(contenido_data.dict())
        return contenido_creado
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear el contenido: {str(e)}")

@admin_contenido_router.post("/con-archivo", response_model=ContenidoRead, status_code=status.HTTP_201_CREATED)
async def crear_contenido_con_archivo(
    titulo: str = Query(...),
    descripcion: str = Query(...),
    categoria: str = Query(...),
    archivo: UploadFile = File(...),
    es_publico: bool = Query(True, description="Indica si el contenido es público"),
    session: Session = Depends(get_session)
):
    """Crear contenido con upload de archivo - Solo para administradores"""
    try:
        # Validar tipo de archivo
        allowed_types = {
            'image/jpeg': 'imagen',
            'image/png': 'imagen', 
            'image/gif': 'imagen',
            'application/pdf': 'documento',
            'application/msword': 'documento',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'documento',
            'video/mp4': 'video',
            'video/mpeg': 'video',
            'audio/mpeg': 'audio'
        }
        
        if archivo.content_type not in allowed_types:
            raise HTTPException(
                status_code=400, 
                detail=f"Tipo de archivo no permitido. Tipos permitidos: {', '.join(allowed_types.keys())}"
            )
        
        # Guardar archivo
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_filename = "".join(c for c in archivo.filename if c.isalnum() or c in (' ', '-', '_', '.')).rstrip()
        filename = f"{timestamp}_{safe_filename}"
        file_path = os.path.join(UPLOAD_DIR, filename)
        
        with open(file_path, "wb") as buffer:
            content = await archivo.read()
            buffer.write(content)
        
        # Crear contenido en base de datos
        contenido_data = {
            'titulo': titulo,
            'descripcion': descripcion,
            'categoria': categoria,
            'url': f"/uploads/contenidos/{filename}",
            'tipo_archivo': archivo.content_type,
            'tipo_contenido': allowed_types[archivo.content_type],
            'activo': True,
            'es_publico': es_publico,
            'tamaño_archivo': len(content)
        }
        
        caso_uso = CrearContenidoCase(session)
        contenido_creado = caso_uso.ejecutar(contenido_data)
        
        return contenido_creado
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear contenido: {str(e)}")

@admin_contenido_router.put("/{contenido_id}", response_model=ContenidoRead)
def actualizar_contenido_admin(
    contenido_id: int,
    contenido_data: ContenidoUpdate,
    session: Session = Depends(get_session)
):
    """Actualizar un contenido existente - Solo para administradores"""
    caso_uso = ModificarContenidoCase(session)
    
    try:
        datos_actualizacion = contenido_data.dict(exclude_unset=True)
        contenido_actualizado = caso_uso.ejecutar(contenido_id, datos_actualizacion)
        return contenido_actualizado
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el contenido: {str(e)}")

@admin_contenido_router.put("/{contenido_id}/archivo", response_model=ContenidoRead)
async def actualizar_archivo_contenido(
    contenido_id: int,
    archivo: UploadFile = File(...),
    session: Session = Depends(get_session)
):
    """Actualizar el archivo de un contenido existente - Solo para administradores"""
    repository = AdaptadorContenidoSQL(session)
    
    # Verificar que el contenido existe
    contenido_existente = repository.obtener_contenido_por_id(contenido_id)
    if not contenido_existente:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    
    try:
        # Validar tipo de archivo
        allowed_types = ['image/jpeg', 'image/png', 'application/pdf', 'video/mp4', 'audio/mpeg']
        if archivo.content_type not in allowed_types:
            raise HTTPException(status_code=400, detail="Tipo de archivo no permitido")
        
        # Guardar nuevo archivo
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_{archivo.filename}"
        file_path = os.path.join(UPLOAD_DIR, filename)
        
        with open(file_path, "wb") as buffer:
            content = await archivo.read()
            buffer.write(content)
        
        # Actualizar contenido
        datos_actualizacion = {
            'url': f"/uploads/contenidos/{filename}",
            'tipo_archivo': archivo.content_type,
            'tamaño_archivo': len(content),
            'fecha_actualizacion': datetime.now()
        }
        
        caso_uso = ModificarContenidoCase(session)
        contenido_actualizado = caso_uso.ejecutar(contenido_id, datos_actualizacion)
        
        # Eliminar archivo anterior si existe
        if contenido_existente.url and contenido_existente.url.startswith("/uploads/contenidos/"):
            old_file_path = contenido_existente.url.replace("/uploads/contenidos/", UPLOAD_DIR + "/")
            if os.path.exists(old_file_path):
                os.remove(old_file_path)
        
        return contenido_actualizado
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar archivo: {str(e)}")

@admin_contenido_router.delete("/{contenido_id}", status_code=status.HTTP_200_OK)
def desactivar_contenido(
    contenido_id: int,
    session: Session = Depends(get_session)
):
    """Desactivar un contenido (soft delete) - Solo para administradores"""
    caso_uso = EliminarContenidoCase(session)
    
    try:
        eliminado = caso_uso.ejecutar(contenido_id)
        if eliminado:
            return {"message": "Contenido desactivado correctamente"}
        else:
            raise HTTPException(status_code=404, detail="Contenido no encontrado")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al desactivar el contenido: {str(e)}")

@admin_contenido_router.delete("/{contenido_id}/permanent", status_code=status.HTTP_200_OK)
def eliminar_contenido_permanentemente(
    contenido_id: int,
    session: Session = Depends(get_session)
):
    """Eliminar un contenido permanentemente (incluyendo archivo) - Solo para administradores"""
    repository = AdaptadorContenidoSQL(session)
    
    # Obtener contenido antes de eliminar
    contenido = repository.obtener_contenido_por_id(contenido_id)
    if not contenido:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    
    try:
        # Eliminar archivo físico si existe
        if contenido.url and contenido.url.startswith("/uploads/contenidos/"):
            file_path = contenido.url.replace("/uploads/contenidos/", UPLOAD_DIR + "/")
            if os.path.exists(file_path):
                os.remove(file_path)
        
        # Eliminar de la base de datos
        eliminado = repository.eliminar_contenido_permanentemente(contenido_id)
        
        if eliminado:
            return {"message": "Contenido eliminado permanentemente"}
        else:
            raise HTTPException(status_code=500, detail="Error al eliminar el contenido")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar contenido: {str(e)}")

@admin_contenido_router.patch("/{contenido_id}/activar", response_model=ContenidoRead)
def activar_contenido_admin(
    contenido_id: int,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Reactivar un contenido desactivado - Solo para administradores"""
    contenido_activado = repository.activar_contenido(contenido_id)
    if not contenido_activado:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    return contenido_activado

@admin_contenido_router.patch("/{contenido_id}/visibilidad")
def cambiar_visibilidad_contenido(
    contenido_id: int,
    es_publico: bool = Query(..., description="Nuevo estado de visibilidad"),
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Cambiar la visibilidad de un contenido - Solo para administradores"""
    contenido_actualizado = repository.cambiar_visibilidad(contenido_id, es_publico)
    if not contenido_actualizado:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    
    return {
        "message": f"Contenido marcado como {'público' if es_publico else 'privado'}",
        "contenido": ContenidoRead.from_orm(contenido_actualizado)
    }

@admin_contenido_router.get("/{contenido_id}/estadisticas")
def obtener_estadisticas_contenido(
    contenido_id: int,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener estadísticas de un contenido - Solo para administradores"""
    contenido = repository.obtener_contenido_por_id(contenido_id)
    if not contenido:
        raise HTTPException(status_code=404, detail="Contenido no encontrado")
    
    # Estadísticas extendidas (puedes ampliar según tu modelo)
    estadisticas = repository.obtener_estadisticas_contenido(contenido_id)
    
    return {
        'contenido_id': contenido_id,
        'titulo': contenido.titulo,
        'categoria': contenido.categoria,
        'tipo_contenido': contenido.tipo_contenido,
        'fecha_creacion': contenido.fecha_creacion,
        'fecha_actualizacion': contenido.fecha_actualizacion,
        'activo': contenido.activo,
        'es_publico': contenido.es_publico,
        'tipo_archivo': contenido.tipo_archivo,
        'tamaño_archivo': contenido.tamaño_archivo,
        'estadisticas': estadisticas
    }

@admin_contenido_router.get("/reporte/categorias")
def generar_reporte_categorias(
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Generar reporte de contenidos por categoría - Solo para administradores"""
    categorias = repository.listar_categorias()
    
    reporte = []
    for categoria in categorias:
        contenidos_activos = repository.listar_contenidos_por_categoria(categoria, activos=True)
        contenidos_inactivos = repository.listar_contenidos_por_categoria(categoria, activos=False)
        todos_contenidos = contenidos_activos + contenidos_inactivos
        
        # Calcular estadísticas por tipo de contenido
        tipos_contenido = {}
        for contenido in todos_contenidos:
            tipo = contenido.tipo_contenido or 'otros'
            if tipo not in tipos_contenido:
                tipos_contenido[tipo] = 0
            tipos_contenido[tipo] += 1
        
        # Calcular tamaño total
        tamaño_total = sum(c.tamaño_archivo or 0 for c in todos_contenidos)
        
        reporte.append({
            'categoria': categoria,
            'total_contenidos': len(todos_contenidos),
            'contenidos_activos': len(contenidos_activos),
            'contenidos_inactivos': len(contenidos_inactivos),
            'contenidos_publicos': len([c for c in todos_contenidos if c.es_publico]),
            'tamaño_total_bytes': tamaño_total,
            'tamaño_total_mb': round(tamaño_total / (1024 * 1024), 2),
            'tipos_contenido': tipos_contenido,
            'ultima_actualizacion': max(
                [c.fecha_actualizacion for c in todos_contenidos if c.fecha_actualizacion], 
                default=None
            )
        })
    
    return sorted(reporte, key=lambda x: x['total_contenidos'], reverse=True)

@admin_contenido_router.get("/reporte/tipos-contenido")
def generar_reporte_tipos_contenido(
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Generar reporte de contenidos por tipo - Solo para administradores"""
    contenidos = repository.listar_todos_los_contenidos()
    
    reporte = {}
    for contenido in contenidos:
        tipo = contenido.tipo_contenido or 'otros'
        if tipo not in reporte:
            reporte[tipo] = {
                'total': 0,
                'activos': 0,
                'inactivos': 0,
                'publicos': 0,
                'tamaño_total': 0,
                'categorias': {}
            }
        
        reporte[tipo]['total'] += 1
        if contenido.activo:
            reporte[tipo]['activos'] += 1
        else:
            reporte[tipo]['inactivos'] += 1
        
        if contenido.es_publico:
            reporte[tipo]['publicos'] += 1
        
        reporte[tipo]['tamaño_total'] += contenido.tamaño_archivo or 0
        
        # Agrupar por categorías
        categoria = contenido.categoria
        if categoria not in reporte[tipo]['categorias']:
            reporte[tipo]['categorias'][categoria] = 0
        reporte[tipo]['categorias'][categoria] += 1
    
    # Convertir tamaño a MB y ordenar
    for tipo in reporte:
        reporte[tipo]['tamaño_total_mb'] = round(reporte[tipo]['tamaño_total'] / (1024 * 1024), 2)
    
    return reporte

@admin_contenido_router.get("/categorias/disponibles")
def obtener_categorias_disponibles(
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener lista de categorías disponibles - Solo para administradores"""
    categorias = repository.listar_categorias()
    return {"categorias": categorias}

@admin_contenido_router.get("/categorias/todas", response_model=List[ContenidoCategoriaResponse])
def obtener_contenidos_agrupados_por_categoria(
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Obtener contenidos agrupados por categoría - Solo para administradores"""
    return repository.listar_contenidos_agrupados_por_categoria()

@admin_contenido_router.post("/categorias/{categoria}")
def crear_nueva_categoria(
    categoria: str,
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Crear una nueva categoría (si no existe) - Solo para administradores"""
    try:
        categorias_existentes = repository.listar_categorias()
        if categoria in categorias_existentes:
            raise HTTPException(status_code=400, detail="La categoría ya existe")
        
        # Esta función debería existir en tu repositorio
        categoria_creada = repository.crear_categoria(categoria)
        return {"message": f"Categoría '{categoria}' creada correctamente"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear categoría: {str(e)}")

@admin_contenido_router.get("/buscar/avanzado")
def busqueda_avanzada_contenidos(
    titulo: Optional[str] = Query(None),
    categoria: Optional[str] = Query(None),
    tipo_contenido: Optional[str] = Query(None),
    fecha_inicio: Optional[str] = Query(None),
    fecha_fin: Optional[str] = Query(None),
    solo_publicos: bool = Query(False),
    repository: RepositorioContenido = Depends(get_contenido_repository)
):
    """Búsqueda avanzada de contenidos - Solo para administradores"""
    contenidos = repository.busqueda_avanzada(
        titulo=titulo,
        categoria=categoria,
        tipo_contenido=tipo_contenido,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
        solo_publicos=solo_publicos
    )
    
    return {
        "parametros_busqueda": {
            "titulo": titulo,
            "categoria": categoria,
            "tipo_contenido": tipo_contenido,
            "fecha_inicio": fecha_inicio,
            "fecha_fin": fecha_fin,
            "solo_publicos": solo_publicos
        },
        "total_resultados": len(contenidos),
        "resultados": contenidos
    }