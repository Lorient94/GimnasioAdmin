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

  void _mostrarCrearPago() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CrearPagoWidget(onPreferenciaCreada: (initPoint) async {
          // Si recibimos URL de preferencia, intentamos abrirla
          if (initPoint != null && initPoint.isNotEmpty) {
            final uri = Uri.parse(initPoint);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        title: const Text('Abrir URL'),
                        content: Text('Abre la siguiente URL:\n$initPoint'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cerrar'))
                        ],
                      ));
            }
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<MercadoPagoCubit>().cargarHistorial()),
          IconButton(icon: const Icon(Icons.add), onPressed: _mostrarCrearPago),
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
                  hintText: 'Buscar por estado o cliente...'),
              onChanged: (v) {},
            ),
          ),
          Expanded(
            child: BlocBuilder<MercadoPagoCubit, MercadoPagoState>(
              builder: (context, state) {
                if (state is MercadoPagoLoading)
                  return const Center(child: CircularProgressIndicator());
                if (state is MercadoPagoError)
                  return Center(child: Text('Error: ${state.message}'));
                if (state is MercadoPagoLoaded) {
                  final list = state.pagosFiltrados;
                  if (list.isEmpty)
                    return const Center(child: Text('No hay pagos'));

                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final pago = list[index];
                      return PagoCardWidget(pago: pago);
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
