import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/usuario_cubit.dart';
import 'package:gimnasio_app/Widgets/crear_usuario_widget.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class UsuarioCardWidget extends StatelessWidget {
  final Map<String, dynamic> usuario;
  const UsuarioCardWidget({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title:
            Text('${usuario['nombre'] ?? 'Usuario'} - ${usuario['dni'] ?? ''}'),
        subtitle: Text('Activo: ${usuario['activo'] == true ? 'Sí' : 'No'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final cubit = context.read<UsuarioCubit>();
            switch (value) {
              case 'detalle':
                final detalle =
                    await cubit.obtenerDetalle(usuario['id'] as int);
                showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                            title: const Text('Detalle Usuario'),
                            content: Text(detalle.toString()),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cerrar'))
                            ]));
                break;
              case 'editar':
                showDialog(
                    context: context,
                    builder: (_) => Dialog(
                        child: CrearUsuarioWidget(usuarioInicial: usuario)));
                break;
              case 'activar':
                try {
                  await cubit.activarUsuario(usuario['id'] as int);
                  if (context.mounted)
                    AppSnackBar.show(context, 'Usuario activado');
                } catch (e) {
                  if (context.mounted)
                    AppSnackBar.show(
                        context, 'Error activando usuario: ${e.toString()}',
                        error: true);
                }
                break;
              case 'desactivar':
                try {
                  await cubit.desactivarUsuario(usuario['id'] as int);
                  if (context.mounted)
                    AppSnackBar.show(context, 'Usuario desactivado');
                } catch (e) {
                  if (context.mounted)
                    AppSnackBar.show(
                        context, 'Error desactivando usuario: ${e.toString()}',
                        error: true);
                }
                break;
              case 'eliminar':
                final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                            title: const Text('Eliminar usuario'),
                            content: const Text('¿Eliminar usuario?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancelar')),
                              ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Eliminar'))
                            ]));
                if (confirm == true) {
                  try {
                    await cubit.eliminarUsuario(usuario['id'] as int);
                    if (context.mounted)
                      AppSnackBar.show(context, 'Usuario eliminado');
                  } catch (e) {
                    if (context.mounted)
                      AppSnackBar.show(
                          context, 'Error eliminando usuario: ${e.toString()}',
                          error: true);
                  }
                }
                break;
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'detalle', child: Text('Detalle')),
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'activar', child: Text('Activar')),
            PopupMenuItem(value: 'desactivar', child: Text('Desactivar')),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
