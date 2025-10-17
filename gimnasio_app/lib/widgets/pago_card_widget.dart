import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/mercado_pago_cubit.dart';
import 'package:gimnasio_app/Widgets/crear_pago_widget.dart';
import 'package:gimnasio_app/utils/snackbars.dart';
import 'package:url_launcher/url_launcher.dart';

class PagoCardWidget extends StatelessWidget {
  final Map<String, dynamic> pago;
  const PagoCardWidget({super.key, required this.pago});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text('Pago #${pago['id'] ?? 'N/A'} - ${pago['estado'] ?? ''}'),
        subtitle: Text('Cliente: ${pago['cliente'] ?? 'N/A'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final cubit = context.read<MercadoPagoCubit>();
            try {
              switch (value) {
                case 'editar':
                  // Abrir formulario prellenado para editar
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CrearPagoWidget(
                          pagoInicial: pago, // Ahora sí existe
                          onPreferenciaCreada: (initPoint) async {
                            if (initPoint != null && initPoint.isNotEmpty) {
                              final uri = Uri.parse(initPoint);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Abrir URL'),
                                    content: Text(
                                        'No se pudo abrir automáticamente:\n$initPoint'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cerrar'),
                                      )
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  );
                  break;

                case 'detalle':
                  final detalle = await cubit.obtenerDetalle(pago['id'] as int);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Detalle Pago'),
                      content: Text(detalle.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        )
                      ],
                    ),
                  );
                  break;

                case 'verificar':
                  final detalle = await cubit.verificarPago(pago['id'] as int);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Verificar Pago'),
                      content: Text(detalle.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        )
                      ],
                    ),
                  );
                  AppSnackBar.show(context, 'Verificación realizada');
                  break;

                case 'reembolsar':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirmar Reembolso'),
                      content: const Text('¿Deseas reembolsar este pago?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Reembolsar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await cubit.reembolsarPago(pago['id'] as int);
                    AppSnackBar.show(context, 'Pago reembolsado');
                  }
                  break;
              }
            } catch (e) {
              AppSnackBar.show(context, 'Error: ${e.toString()}', error: true);
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'detalle', child: Text('Detalle')),
            PopupMenuItem(value: 'verificar', child: Text('Verificar')),
            PopupMenuItem(value: 'reembolsar', child: Text('Reembolsar')),
          ],
        ),
      ),
    );
  }
}
