// widgets/inscripcion_card_widget.dart
import 'package:flutter/material.dart';

class InscripcionCardWidget extends StatelessWidget {
  final Map<String, dynamic> inscripcion;
  final VoidCallback? onCancelar;
  final VoidCallback? onReactivar;
  final VoidCallback? onCompletar;
  final VoidCallback? onVerDetalles;

  const InscripcionCardWidget({
    Key? key,
    required this.inscripcion,
    this.onCancelar,
    this.onReactivar,
    this.onCompletar,
    this.onVerDetalles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nombre = inscripcion['nombre_cliente']?.toString() ?? 'Cliente';
    final email = inscripcion['email_cliente']?.toString() ?? 'Sin email';
    final clase = inscripcion['clase_nombre']?.toString() ?? 'Clase';
    final estado = inscripcion['estado']?.toString() ?? 'Desconocido';
    final fecha = inscripcion['fecha_inscripcion']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C'),
        ),
        title: Text(nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$email • $clase'),
            if (fecha.isNotEmpty)
              Text('Fecha: $fecha', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                estado,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getColorEstado(estado),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuSelection(value, context),
              itemBuilder: (context) => _buildMenuItems(estado),
            ),
          ],
        ),
        onTap: onVerDetalles,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(String estado) {
    final items = <PopupMenuEntry<String>>[];

    items.add(
        const PopupMenuItem(value: 'detalles', child: Text('Ver Detalles')));

    if (estado.toLowerCase() == 'activa') {
      items
          .add(const PopupMenuItem(value: 'cancelar', child: Text('Cancelar')));
      items.add(
          const PopupMenuItem(value: 'completar', child: Text('Completar')));
    } else if (estado.toLowerCase() == 'cancelada') {
      items.add(
          const PopupMenuItem(value: 'reactivar', child: Text('Reactivar')));
    } else if (estado.toLowerCase() == 'pendiente') {
      items
          .add(const PopupMenuItem(value: 'cancelar', child: Text('Cancelar')));
    }

    return items;
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'detalles':
        onVerDetalles?.call();
        break;
      case 'cancelar':
        onCancelar?.call();
        break;
      case 'reactivar':
        onReactivar?.call();
        break;
      case 'completar':
        onCompletar?.call();
        break;
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'activa':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'completada':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
