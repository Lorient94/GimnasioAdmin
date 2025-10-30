import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/transaccion_cubit.dart';
import 'package:gimnasio_app/Widgets/transaccion_card_widget.dart';
import 'package:gimnasio_app/Widgets/crear_transaccion_widget.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class TransaccionesScreen extends StatefulWidget {
  const TransaccionesScreen({super.key});

  @override
  State<TransaccionesScreen> createState() => _TransaccionesScreenState();
}

class _TransaccionesScreenState extends State<TransaccionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _cargarTransacciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarTransacciones() async {
    try {
      setState(() {
        _isRefreshing = true;
      });
      await context.read<TransaccionCubit>().cargarTransacciones();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error al cargar transacciones: $e',
            error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _mostrarCrear() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: CrearTransaccionWidget(
            // ✅ CORREGIDO: Removido el parámetro que no existe
            ),
      ),
    ).then((_) {
      // ✅ CORREGIDO: Recargar después de cerrar el diálogo
      _cargarTransacciones();
    });
  }

  // ✅ CORREGIDO: Cambiado a Future<void> para RefreshIndicator
  Future<void> _onRefresh() async {
    await _cargarTransacciones();
    if (mounted) {
      AppSnackBar.show(context, 'Transacciones actualizadas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _onRefresh,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarCrear,
            tooltip: 'Crear transacción',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por cliente, estado o referencia',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) =>
                  context.read<TransaccionCubit>().filtrarTransacciones(v),
            ),
          ),

          // Indicador de carga durante refresh
          if (_isRefreshing) const LinearProgressIndicator(),

          // Lista de transacciones
          Expanded(
            child: BlocBuilder<TransaccionCubit, TransaccionState>(
              builder: (context, state) {
                // Estado de carga inicial
                if (state is TransaccionLoading && !_isRefreshing) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando transacciones...'),
                      ],
                    ),
                  );
                }

                // Estado de error
                if (state is TransaccionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarTransacciones,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                // Estado cargado
                if (state is TransaccionLoaded) {
                  final list = state.transaccionesFiltradas;

                  // Lista vacía
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No hay transacciones'
                                : 'No se encontraron resultados',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<TransaccionCubit>()
                                    .filtrarTransacciones('');
                              },
                              child: const Text('Limpiar búsqueda'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _mostrarCrear,
                            child: const Text('Crear primera transacción'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Lista con datos
                  return RefreshIndicator(
                    onRefresh: _onRefresh, // ✅ CORREGIDO: Ahora es compatible
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final transaccion = list[index];
                        return TransaccionCardWidget(transaccion: transaccion);
                      },
                    ),
                  );
                }

                // Estado inicial
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Inicializando...'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Botón flotante para crear transacción
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarCrear,
        child: const Icon(Icons.add),
        tooltip: 'Crear transacción',
      ),
    );
  }
}
