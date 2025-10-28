import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/usuario_cubit.dart';
import 'package:gimnasio_app/Screens/usuario_inscripciones_screen.dart';
import 'package:gimnasio_app/Widgets/crear_usuario_widget.dart';
import 'package:gimnasio_app/utils/snackbars.dart';
import 'package:gimnasio_app/screens/usuario_detail_screen.dart';

class UsuarioCardWidget extends StatelessWidget {
  final Map<String, dynamic> usuario;
  const UsuarioCardWidget({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UsuarioDetailScreen(usuario: usuario),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar del usuario
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (usuario['activo'] == true ? Colors.green : Colors.red)
                      .withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: usuario['activo'] == true ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario['nombre'] ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DNI: ${usuario['dni'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario['correo'] ?? 'Sin correo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Estado y menú
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          usuario['activo'] == true ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      usuario['activo'] == true ? 'Activo' : 'Inactivo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'detalle', child: Text('Ver Detalle')),
        const PopupMenuItem(value: 'editar', child: Text('Editar')),
        const PopupMenuItem(
            value: 'inscripciones', child: Text('Ver Inscripciones')),
        const PopupMenuItem(value: 'pagos', child: Text('Ver Pagos')),
        PopupMenuItem(
          value: usuario['activo'] == true ? 'desactivar' : 'activar',
          child: Text(usuario['activo'] == true ? 'Desactivar' : 'Activar'),
        ),
        const PopupMenuItem(
            value: 'eliminar',
            child: Text('Eliminar', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    final cubit = context.read<UsuarioCubit>();

    switch (value) {
      case 'detalle':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UsuarioDetailScreen(usuario: usuario),
          ),
        );
        break;
      case 'editar':
        showDialog(
          context: context,
          builder: (_) =>
              Dialog(child: CrearUsuarioWidget(usuarioInicial: usuario)),
        );
        break;
      case 'inscripciones':
        // Navegar a pantalla de inscripciones del usuario
        _navigateToInscripciones(context);
        break;
      case 'pagos':
        // Navegar a pantalla de pagos del usuario
        _navigateToPagos(context);
        break;
      case 'activar':
        _handleActivarUsuario(context, cubit);
        break;
      case 'desactivar':
        _handleDesactivarUsuario(context, cubit);
        break;
      case 'eliminar':
        _handleEliminarUsuario(context, cubit);
        break;
    }
  }

  void _navigateToInscripciones(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioInscripcionesScreen(usuario: usuario),
      ),
    );
  }

  void _navigateToPagos(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver pagos de ${usuario['nombre']}')),
    );
  }

  void _handleActivarUsuario(BuildContext context, UsuarioCubit cubit) async {
    try {
      await cubit.activarUsuario(usuario['id'] as int);
      if (context.mounted) {
        AppSnackBar.show(context, 'Usuario activado correctamente');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, 'Error activando usuario: ${e.toString()}',
            error: true);
      }
    }
  }

  void _handleDesactivarUsuario(
      BuildContext context, UsuarioCubit cubit) async {
    try {
      await cubit.desactivarUsuario(usuario['id'] as int);
      if (context.mounted) {
        AppSnackBar.show(context, 'Usuario desactivado correctamente');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, 'Error desactivando usuario: ${e.toString()}',
            error: true);
      }
    }
  }

  void _handleEliminarUsuario(BuildContext context, UsuarioCubit cubit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text(
            '¿Estás seguro de eliminar a ${usuario['nombre']}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await cubit.eliminarUsuario(usuario['id'] as int);
        if (context.mounted) {
          AppSnackBar.show(context, 'Usuario eliminado correctamente');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.show(context, 'Error eliminando usuario: ${e.toString()}',
              error: true);
        }
      }
    }
  }
}
