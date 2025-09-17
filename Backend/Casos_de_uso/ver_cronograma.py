from datetime import datetime, timedelta
from Dominio.repositorios.repositorioInscripciones import RepositorioInscripciones

def ver_cronograma(cliente_dni: str, repositorio: RepositorioInscripciones):
    """
    Genera cronograma de clases recurrentes para un cliente,
    considerando solo sus inscripciones activas.
    """
    # Obtener solo inscripciones activas del cliente
    inscripciones = repositorio.ver_inscripciones_cliente(cliente_dni)
    cronograma = []

    dias_map = {
        "lunes": 0,
        "martes": 1,
        "miercoles": 2,
        "miércoles": 2,
        "jueves": 3,
        "viernes": 4,
        "sabado": 5,
        "sábado": 5,
        "domingo": 6
    }

    hoy = datetime.now()
    fin_periodo = hoy + timedelta(days=90)  # próximos 3 meses

    for inscripcion in inscripciones:
        if inscripcion.estado.lower() != "activo":
            continue  # ignorar inscripciones canceladas o completadas

        clase = inscripcion.clase
        if not clase or not clase.activa:
            continue  # ignorar clases inactivas

        for dia in clase.dias_semana:
            weekday = dias_map.get(dia.lower())
            if weekday is None:
                continue

            # Calcular la primera fecha futura que coincida con el día de la clase
            fecha = hoy
            dias_a_sumar = (weekday - fecha.weekday() + 7) % 7
            fecha = fecha + timedelta(days=dias_a_sumar)

            # Iterar semanalmente hasta fin_periodo
            while fecha <= fin_periodo:
                try:
                    hora, minuto = map(int, clase.hora.split(":"))
                except Exception:
                    hora, minuto = 0, 0

                fecha_clase = fecha.replace(hour=hora, minute=minuto, second=0, microsecond=0)

                cronograma.append({
                    "clase_id": clase.id,
                    "nombre": clase.nombre,
                    "descripcion": getattr(clase, "descripcion", ""),
                    "fecha": fecha_clase
                })

                fecha += timedelta(days=7)  # siguiente semana

    # Ordenar cronograma por fecha
    cronograma.sort(key=lambda x: x["fecha"])
    return cronograma
