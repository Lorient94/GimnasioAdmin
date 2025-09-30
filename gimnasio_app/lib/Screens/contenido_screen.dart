import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/contenido_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class ContenidoScreen extends StatefulWidget {
  const ContenidoScreen({Key? key}) : super(key: key);

  @override
  State<ContenidoScreen> createState() => _ContenidoScreenState();
}

class _ContenidoScreenState extends State<ContenidoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _categoriaFiltro = 'todas';

  @override
  void initState() {
    super.initState();
    context.read<ContenidoCubit>().cargarContenidos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _aplicarFiltros() {
    context.read<ContenidoCubit>().filtrarContenidos(
          titulo:
              _searchController.text.isEmpty ? null : _searchController.text,
          categoria: _categoriaFiltro,
        );
  }

  void _mostrarCrearContenido() {
    final TextEditingController _tituloCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Crear Contenido',
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
                            .read<ContenidoCubit>()
                            .crearContenido({'titulo': titulo});
                        AppSnackBar.show(
                            context, 'Contenido creado correctamente');
                        Navigator.of(context).pop();
                      } catch (e) {
                        AppSnackBar.show(
                            context, 'Error creando contenido: ${e.toString()}',
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
        title: const Text('Gestión de Contenido'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<ContenidoCubit>().cargarContenidos()),
          IconButton(
              icon: const Icon(Icons.add), onPressed: _mostrarCrearContenido),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por título...'),
                    onChanged: (_) => _aplicarFiltros(),
                  ),
                ),
                const SizedBox(width: 12),
                BlocBuilder<ContenidoCubit, ContenidoState>(
                    builder: (context, state) {
                  List<String> categorias = ['todas'];
                  if (state is ContenidoLoaded) {
                    categorias = ['todas', ...state.categorias];
                  }

                  return DropdownButton<String>(
                    value: _categoriaFiltro,
                    items: categorias
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _categoriaFiltro = v ?? 'todas');
                      _aplicarFiltros();
                    },
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ContenidoCubit, ContenidoState>(
              builder: (context, state) {
                if (state is ContenidoLoading)
                  return const Center(child: CircularProgressIndicator());
                if (state is ContenidoError)
                  return Center(child: Text('Error: ${state.message}'));
                if (state is ContenidoLoaded) {
                  final list = state.contenidosFiltrados;
                  if (list.isEmpty)
                    return const Center(child: Text('No hay contenido'));

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
                          subtitle: Text(item['categoria']?.toString() ?? ''),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              try {
                                switch (value) {
                                  case 'activar':
                                    await context
                                        .read<ContenidoCubit>()
                                        .activarContenido(item['id'] as int);
                                    AppSnackBar.show(
                                        context, 'Contenido activado');
                                    break;
                                  case 'desactivar':
                                    await context
                                        .read<ContenidoCubit>()
                                        .desactivarContenido(item['id'] as int);
                                    AppSnackBar.show(
                                        context, 'Contenido desactivado');
                                    break;
                                  case 'editar':
                                    // Implementar edición
                                    break;
                                }
                              } catch (e) {
                                AppSnackBar.show(
                                    context, 'Error: ${e.toString()}',
                                    error: true);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                  value: 'editar', child: Text('Editar')),
                              const PopupMenuItem(
                                  value: 'activar', child: Text('Activar')),
                              const PopupMenuItem(
                                  value: 'desactivar',
                                  child: Text('Desactivar')),
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
