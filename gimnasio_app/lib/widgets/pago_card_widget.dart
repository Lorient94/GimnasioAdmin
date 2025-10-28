// widgets/pago_card_widget.dart - VERSIÓN MEJORADA
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/mercado_pago_cubit.dart';

class PagoCardWidget extends StatelessWidget {
  final Map<String, dynamic> pago;

  const PagoCardWidget({super.key, required this.pago});

  @override
  Widget build(BuildContext context) {
    final estado = pago['estado_pago']?.toString() ?? 'pendiente';
    final monto =
        pago['monto'] != null ? double.tryParse(pago['monto'].toString()) : 0.0;
    final fecha = _parseFecha(pago['fecha_creacion']);
    final concepto = pago['concepto']?.toString() ?? 'Sin concepto';
    final referencia = pago['referencia']?.toString() ?? 'N/A';
    final clienteNombre = pago['cliente_nombre']?.toString() ??
        pago['id_usuario']?.toString() ??
        'Cliente';
    final preferenceId = pago['preference_id']?.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado y monto
            Row(
              children: [
                _buildEstadoChip(estado),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${monto?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'ID: ${pago['id'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Información del pago
            Text(
              concepto,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),

            // Información detallada en columnas compactas
            _buildInfoRow('Cliente', clienteNombre),
            _buildInfoRow('Referencia', referencia),
            if (preferenceId != null)
              _buildInfoRow('Preference ID', preferenceId),
            _buildInfoRow(
                'Fecha', DateFormat('dd/MM/yyyy HH:mm').format(fecha)),

            // Acciones según estado - BOTONES MÁS COMPACTOS
            if (estado == 'pendiente') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32, // Botón más compacto
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.payment, size: 14),
                        label:
                            const Text('Pagar', style: TextStyle(fontSize: 12)),
                        onPressed: () => _abrirPago(context, pago),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 32, // Botón más compacto
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sim_card, size: 14),
                      label:
                          const Text('Simular', style: TextStyle(fontSize: 12)),
                      onPressed: () => _simularPago(context, pago),
                    ),
                  ),
                ],
              ),
            ] else if (estado == 'completado') ...[
              const SizedBox(height: 4),
              Text(
                'Completado: ${DateFormat('dd/MM/yyyy HH:mm').format(_parseFecha(pago['fecha_actualizacion']))}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String texto;
    IconData icon;

    switch (estado.toLowerCase()) {
      case 'completado':
        color = Colors.green;
        texto = 'COMPLETADO';
        icon = Icons.check_circle;
        break;
      case 'pendiente':
        color = Colors.orange;
        texto = 'PENDIENTE';
        icon = Icons.pending;
        break;
      case 'rechazado':
        color = Colors.red;
        texto = 'RECHAZADO';
        icon = Icons.cancel;
        break;
      case 'cancelado':
        color = Colors.grey;
        texto = 'CANCELADO';
        icon = Icons.block;
        break;
      default:
        color = Colors.blue;
        texto = estado.toUpperCase();
        icon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseFecha(dynamic fecha) {
    try {
      if (fecha is String) {
        return DateTime.parse(fecha);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  void _abrirPago(BuildContext context, Map<String, dynamic> pago) {
    final initPoint = pago['init_point']?.toString();
    if (initPoint != null && initPoint.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Abriendo pago: ${pago['referencia']}'),
          duration: const Duration(seconds: 2),
        ),
      );
      // En una implementación real, aquí abrirías la URL
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay URL de pago disponible'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _simularPago(BuildContext context, Map<String, dynamic> pago) {
    final preferenceId = pago['preference_id']?.toString();
    if (preferenceId != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Simular Pago'),
          content: Text('¿Simular pago exitoso para ${pago['concepto']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final cubit = context.read<MercadoPagoCubit>();
                  await cubit.simularPagoExitoso(preferenceId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pago simulado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Simular Éxito'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede simular este pago'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
