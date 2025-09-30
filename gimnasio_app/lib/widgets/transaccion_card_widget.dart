import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/transaccion_cubit.dart';
import 'package:gimnasio_app/Widgets/crear_transaccion_widget.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class TransaccionCardWidget extends StatelessWidget {
  final Map<String, dynamic> transaccion;
  const TransaccionCardWidget({super.key, required this.transaccion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
            'Transacción #${transaccion['id'] ?? 'N/A'} - ${transaccion['estado'] ?? ''}'),
        subtitle: Text(
            'Cliente: ${transaccion['cliente'] ?? 'N/A'} • Monto: ${transaccion['monto'] ?? '0'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final cubit = context.read<TransaccionCubit>();
            try {
              switch (value) {
                case 'detalle':
                  final detalle =
                      await cubit.obtenerDetalle(transaccion['id'] as int);
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text('Detalle Transacción'),
                            content: Text(detalle.toString()),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cerrar'))
                            ],
                          ));
                  break;
                case 'editar':
                  showDialog(
                      context: context,
                      builder: (_) => Dialog(
                          child: CrearTransaccionWidget(
                              transaccionInicial: transaccion)));
                  break;
                case 'pagar':
                  await cubit.marcarComoPagada(transaccion['id'] as int);
                  AppSnackBar.show(context, 'Transacción marcada como pagada');
                  break;
                case 'revertir':
                  final motivoCtrl = TextEditingController();
                  final motivo = await showDialog<String?>(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text('Motivo de reversión'),
                            content: TextField(
                                controller: motivoCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Motivo')),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(null),
                                  child: const Text('Cancelar')),
                              ElevatedButton(
                                  onPressed: () => Navigator.of(context)
                                      .pop(motivoCtrl.text),
                                  child: const Text('Revertir'))
                            ],
                          ));
                  if (motivo != null && motivo.isNotEmpty) {
                    await cubit.revertirTransaccion(
                        transaccion['id'] as int, motivo);
                    AppSnackBar.show(context, 'Transacción revertida');
                  }
                  break;
                case 'eliminar':
                  final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text('Eliminar transacción'),
                            content:
                                const Text('¿Desea eliminar esta transacción?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancelar')),
                              ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Eliminar'))
                            ],
                          ));
                  if (confirm == true)
                    await cubit.eliminarTransaccion(transaccion['id'] as int);
                  AppSnackBar.show(context, 'Transacción eliminada');
                  break;
              }
            } catch (e) {
              AppSnackBar.show(context, 'Error: ${e.toString()}', error: true);
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'detalle', child: Text('Detalle')),
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'pagar', child: Text('Marcar como pagada')),
            PopupMenuItem(value: 'revertir', child: Text('Revertir')),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
