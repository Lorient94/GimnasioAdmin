import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gimnasio_app/Cubits/mercado_pago_cubit.dart';
import 'package:gimnasio_app/Widgets/pago_card_widget.dart';
import 'package:gimnasio_app/Widgets/crear_pago_widget.dart';

class PagoScreen extends StatefulWidget {
  const PagoScreen({Key? key}) : super(key: key);

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MercadoPagoCubit>().cargarHistorial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Muestra el modal para crear un nuevo pago
  void _mostrarCrearPago() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CrearPagoWidget(
            onPreferenciaCreada: (initPoint) async {
              if (initPoint == null || initPoint.isEmpty) return;
              final uri = Uri.parse(initPoint);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Abrir pago manualmente'),
                    content: Text(
                      'No se pudo abrir la URL automáticamente.\n\n$initPoint',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MercadoPagoCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => cubit.cargarHistorial(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarCrearPago,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por estado, cliente o concepto...',
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) => cubit.filtrarPagos(valor),
            ),
          ),

          // 📋 Lista de pagos
          Expanded(
            child: BlocBuilder<MercadoPagoCubit, MercadoPagoState>(
              builder: (context, state) {
                if (state is MercadoPagoLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MercadoPagoError) {
                  return Center(
                    child: Text('Error: ${state.message}'),
                  );
                }

                if (state is MercadoPagoLoaded) {
                  final pagos = state.pagosFiltrados;
                  if (pagos.isEmpty) {
                    return const Center(
                      child: Text('No hay pagos registrados.'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => cubit.cargarHistorial(),
                    child: ListView.builder(
                      itemCount: pagos.length,
                      itemBuilder: (context, index) {
                        final pago = pagos[index];
                        return PagoCardWidget(pago: pago);
                      },
                    ),
                  );
                }

                return const Center(child: Text('Cargando datos...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
