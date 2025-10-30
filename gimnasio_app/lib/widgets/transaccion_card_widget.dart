// Widgets/transaccion_card_widget.dart - Versión mejorada
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/transaccion_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class TransaccionCardWidget extends StatelessWidget {
  final Map<String, dynamic> transaccion;
  const TransaccionCardWidget({super.key, required this.transaccion});

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
      case 'completado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'rechazada':
      case 'rechazado':
      case 'cancelada':
      case 'cancelado':
        return Colors.red;
      case 'reembolsada':
      case 'reembolsado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
      case 'completado':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.pending;
      case 'rechazada':
      case 'rechazado':
        return Icons.cancel;
      case 'cancelada':
      case 'cancelado':
        return Icons.block;
      case 'reembolsada':
      case 'reembolsado':
        return Icons.assignment_return;
      default:
        return Icons.receipt;
    }
  }

  String _formatMonto(dynamic monto) {
    if (monto == null) return '\$0';
    final amount =
        monto is String ? double.tryParse(monto) ?? 0 : monto.toDouble();
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateStr = date.toString();
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = transaccion['estado']?.toString() ?? 'pendiente';
    final monto = _formatMonto(transaccion['monto']);
    final referencia = transaccion['referencia']?.toString() ?? 'N/A';
    final clienteDni = transaccion['cliente_dni']?.toString() ?? 'N/A';
    final fecha =
        _formatDate(transaccion['fecha'] ?? transaccion['fecha_creacion']);
    final metodoPago = transaccion['metodo_pago']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getEstadoColor(estado).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getEstadoIcon(estado),
            color: _getEstadoColor(estado),
            size: 20,
          ),
        ),
        title: Text(
          'Transacción #${transaccion['id'] ?? 'N/A'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: $clienteDni'),
            Text('Monto: $monto • ${estado.toUpperCase()}'),
            Text('Ref: $referencia • $fecha'),
            if (metodoPago != 'N/A') Text('Método: $metodoPago'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onMenuSelected(value, context),
          itemBuilder: (context) => _buildMenuItems(estado),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(String estado) {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'detalle', child: Text('Ver detalle')),
      const PopupMenuItem(value: 'editar', child: Text('Editar')),
    ];

    if (estado.toLowerCase() == 'pendiente') {
      items.add(const PopupMenuItem(
          value: 'pagar', child: Text('Marcar como pagada')));
    }

    if (estado.toLowerCase() == 'completada' ||
        estado.toLowerCase() == 'completado') {
      items
          .add(const PopupMenuItem(value: 'revertir', child: Text('Revertir')));
    }

    items.add(const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')));

    return items;
  }

  void _onMenuSelected(String value, BuildContext context) async {
    final cubit = context.read<TransaccionCubit>();
    final transaccionId = transaccion['id'] as int?;

    if (transaccionId == null) {
      AppSnackBar.show(context, 'Error: ID de transacción no válido',
          error: true);
      return;
    }

    try {
      switch (value) {
        case 'detalle':
          final detalle = await cubit.obtenerDetalle(transaccionId);
          _mostrarDetalleDialog(context, detalle);
          break;
        case 'editar':
          // TODO: Implementar edición
          AppSnackBar.show(context, 'Edición de transacción - Próximamente');
          break;
        case 'pagar':
          await cubit.marcarComoPagada(transaccionId);
          AppSnackBar.show(context, 'Transacción marcada como pagada');
          break;
        case 'revertir':
          final motivo = await _solicitarMotivo(context);
          if (motivo != null && motivo.isNotEmpty) {
            await cubit.revertirTransaccion(transaccionId, motivo);
            AppSnackBar.show(context, 'Transacción revertida');
          }
          break;
        case 'eliminar':
          final confirmado = await _confirmarEliminacion(context);
          if (confirmado == true) {
            await cubit.eliminarTransaccion(transaccionId);
            AppSnackBar.show(context, 'Transacción eliminada');
          }
          break;
      }
    } catch (e) {
      AppSnackBar.show(context, 'Error: ${e.toString()}', error: true);
    }
  }

  void _mostrarDetalleDialog(
      BuildContext context, Map<String, dynamic> detalle) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalle de Transacción'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('ID', detalle['id']),
              _buildDetalleItem('Referencia', detalle['referencia']),
              _buildDetalleItem('Cliente DNI', detalle['cliente_dni']),
              _buildDetalleItem('Monto', _formatMonto(detalle['monto'])),
              _buildDetalleItem('Estado', detalle['estado']),
              _buildDetalleItem('Método de Pago', detalle['metodo_pago']),
              _buildDetalleItem('Fecha', _formatDate(detalle['fecha'])),
              if (detalle['concepto'] != null)
                _buildDetalleItem('Concepto', detalle['concepto']),
              if (detalle['observaciones'] != null)
                _buildDetalleItem('Observaciones', detalle['observaciones']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? 'N/A')),
        ],
      ),
    );
  }

  Future<String?> _solicitarMotivo(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo de reversión'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Ingrese el motivo de la reversión',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Revertir'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmarEliminacion(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: const Text(
            '¿Está seguro de que desea eliminar esta transacción? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
