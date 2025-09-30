// widgets/clase_list_widget.dart
import 'package:flutter/material.dart';

class ClaseListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> clases;
  final Function(Map<String, dynamic>)? onEditarClase;
  final Function(Map<String, dynamic>)? onActivarClase;
  final Function(Map<String, dynamic>)? onDesactivarClase;
  final Function(Map<String, dynamic>)? onDuplicarClase;
  final Function(Map<String, dynamic>)? onVerInscripciones;
  final Function(Map<String, dynamic>)? onVerEstadisticas;
  final Function(Map<String, dynamic>)? onVerDetalles;

  const ClaseListWidget({
    Key? key,
    required this.clases,
    this.onEditarClase,
    this.onActivarClase,
    this.onDesactivarClase,
    this.onDuplicarClase,
    this.onVerInscripciones,
    this.onVerEstadisticas,
    this.onVerDetalles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (clases.isEmpty) {
      return const Center(child: Text('No hay clases disponibles'));
    }

    return ListView.builder(
      itemCount: clases.length,
      itemBuilder: (context, index) {
        final clase = clases[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(clase['nombre'] ?? 'Sin nombre'),
            subtitle: Text('Instructor: ${clase['instructor']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onVerDetalles != null)
                  IconButton(
                    icon: const Icon(Icons.info),
                    onPressed: () => onVerDetalles!(clase),
                  ),
                if (onEditarClase != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onEditarClase!(clase),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'editar':
                        onEditarClase?.call(clase);
                        break;
                      case 'activar':
                        onActivarClase?.call(clase);
                        break;
                      case 'desactivar':
                        onDesactivarClase?.call(clase);
                        break;
                      case 'duplicar':
                        onDuplicarClase?.call(clase);
                        break;
                      case 'inscripciones':
                        onVerInscripciones?.call(clase);
                        break;
                      case 'estadisticas':
                        onVerEstadisticas?.call(clase);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEditarClase != null)
                      const PopupMenuItem(
                          value: 'editar', child: Text('Editar')),
                    if (clase['activa'] == true && onDesactivarClase != null)
                      const PopupMenuItem(
                          value: 'desactivar', child: Text('Desactivar')),
                    if (clase['activa'] == false && onActivarClase != null)
                      const PopupMenuItem(
                          value: 'activar', child: Text('Activar')),
                    if (onDuplicarClase != null)
                      const PopupMenuItem(
                          value: 'duplicar', child: Text('Duplicar')),
                    if (onVerInscripciones != null)
                      const PopupMenuItem(
                          value: 'inscripciones',
                          child: Text('Ver Inscripciones')),
                    if (onVerEstadisticas != null)
                      const PopupMenuItem(
                          value: 'estadisticas', child: Text('Estadísticas')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
