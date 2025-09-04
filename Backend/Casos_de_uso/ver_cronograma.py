from Dominio.repositorios.repositorioInscripciones import RepositorioInscripciones

def ver_cronograma(cliente_dni: str, repositorio: RepositorioInscripciones):
    inscripciones = repositorio.ver_inscripciones_cliente(cliente_dni)
    return inscripciones