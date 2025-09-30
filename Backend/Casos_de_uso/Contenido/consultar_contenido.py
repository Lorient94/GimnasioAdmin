from Dominio.repositorios.repositorioContenido import RepositorioContenido

def consultar_contenido(repositorio: RepositorioContenido, nombre: str = None, categoria: str = None, fecha: str = None):
    if nombre:
        return repositorio.buscar_contenidos(nombre)
    if categoria:
        return repositorio.listar_contenidos(activos=True, categoria=categoria)
    if fecha:
        return repositorio.buscar_contenidos_por_fecha(fecha, activos=True)
    return repositorio.listar_contenidos(activos=True)