from Dominio.repositorios.repositorioInscripciones import RepositorioInscripciones

def cancelar_inscripcion(inscripcion_id: int, motivo: str, repositorio: RepositorioInscripciones):
    resultado = repositorio.cancelar_inscripcion(inscripcion_id, motivo)
    if not resultado:
        raise ValueError("No se pudo cancelar la inscripción")
    return resultado