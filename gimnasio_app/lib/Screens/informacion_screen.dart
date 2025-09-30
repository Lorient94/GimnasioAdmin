import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/informacion_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class InformacionScreen extends StatefulWidget {
  const InformacionScreen({Key? key}) : super(key: key);

  @override
  State<InformacionScreen> createState() => _InformacionScreenState();
}

class _InformacionScreenState extends State<InformacionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InformacionCubit>().cargarInformaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _mostrarCrear() {
    final TextEditingController _tituloCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Crear Información',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                  controller: _tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Título')),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar')),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () async {
                      final titulo = _tituloCtrl.text.trim();
                      if (titulo.isEmpty) {
                        AppSnackBar.show(context, 'Ingrese un título',
                            error: true);
                        return;
                      }
                      try {
                        await context
                            .read<InformacionCubit>()
                            .crearInformacion({'titulo': titulo});
                        AppSnackBar.show(
                            context, 'Información creada correctamente');
                        Navigator.of(context).pop();
                      } catch (e) {
                        AppSnackBar.show(context,
                            'Error creando información: ${e.toString()}',
                            error: true);
                      }
                    },
                    child: const Text('Crear')),
              ])
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<InformacionCubit>().cargarInformaciones()),
          IconButton(icon: const Icon(Icons.add), onPressed: _mostrarCrear),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por título o contenido...'),
              onChanged: (v) =>
                  context.read<InformacionCubit>().filtrarLocalmente(v),
            ),
          ),
          Expanded(
            child: BlocBuilder<InformacionCubit, InformacionState>(
              builder: (context, state) {
                if (state is InformacionLoading)
                  return const Center(child: CircularProgressIndicator());
                if (state is InformacionError)
                  return Center(child: Text('Error: ${state.message}'));
                if (state is InformacionLoaded) {
                  final list = state.filtradas;
                  if (list.isEmpty)
                    return const Center(child: Text('No hay informaciones'));

                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title:
                              Text(item['titulo']?.toString() ?? 'Sin título'),
                          subtitle: Text(item['tipo']?.toString() ?? ''),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              try {
                                switch (value) {
                                  case 'editar':
                                    // Implementar edición
                                    break;
                                  case 'activar':
                                    await context
                                        .read<InformacionCubit>()
                                        .activarInformacion(item['id'] as int);
                                    AppSnackBar.show(
                                        context, 'Información activada');
                                    break;
                                  case 'desactivar':
                                    await context
                                        .read<InformacionCubit>()
                                        .desactivarInformacion(
                                            item['id'] as int);
                                    AppSnackBar.show(
                                        context, 'Información desactivada');
                                    break;
                                  case 'eliminar':
                                    await context
                                        .read<InformacionCubit>()
                                        .eliminarInformacion(item['id'] as int);
                                    AppSnackBar.show(
                                        context, 'Información eliminada');
                                    break;
                                }
                              } catch (e) {
                                AppSnackBar.show(
                                    context, 'Error: ${e.toString()}',
                                    error: true);
                              }
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(
                                  value: 'editar', child: Text('Editar')),
                              PopupMenuItem(
                                  value: 'activar', child: Text('Activar')),
                              PopupMenuItem(
                                  value: 'desactivar',
                                  child: Text('Desactivar')),
                              PopupMenuItem(
                                  value: 'eliminar', child: Text('Eliminar')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: Text('Sin datos'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
