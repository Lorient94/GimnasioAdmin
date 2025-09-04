from Dominio.repositorios.repositorioInformacion import RepositorioInformacion

def consultar_informacion(repositorio: RepositorioInformacion, tipo: str = None, destinatario_id: str = None, palabra: str = None, fecha: str = None):
    if palabra:
        return repositorio.buscar_informaciones_por_palabra(palabra)
    if fecha:
        return repositorio.buscar_informaciones_por_fecha(fecha)
    return repositorio.listar_informaciones(tipo=tipo, destinatario_id=destinatario_id)