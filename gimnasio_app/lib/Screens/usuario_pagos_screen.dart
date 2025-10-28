// screens/usuario_pagos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/mercado_pago_cubit.dart';
import 'package:gimnasio_app/Widgets/pago_card_widget.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class UsuarioPagosScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const UsuarioPagosScreen({super.key, required this.usuario});

  @override
  State<UsuarioPagosScreen> createState() => _UsuarioPagosScreenState();
}

class _UsuarioPagosScreenState extends State<UsuarioPagosScreen> {
  @override
  void initState() {
    super.initState();
    _cargarPagosUsuario();
  }

  void _cargarPagosUsuario() {
    final cubit = context.read<MercadoPagoCubit>();
    cubit.cargarHistorial();
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    AppSnackBar.show(context, mensaje, error: esError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos de ${widget.usuario['nombre']}'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPagosUsuario,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: BlocBuilder<MercadoPagoCubit, MercadoPagoState>(
        builder: (context, state) {
          if (state is MercadoPagoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MercadoPagoError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarPagosUsuario,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is MercadoPagoLoaded) {
            // Filtrar pagos por el usuario actual
            final pagosUsuario = state.pagosFiltrados.where((pago) {
              final dniPago = pago['id_usuario']?.toString() ?? '';
              final dniUsuario = widget.usuario['dni']?.toString() ?? '';
              return dniPago == dniUsuario;
            }).toList();

            if (pagosUsuario.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay pagos registrados',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.usuario['nombre']} no tiene pagos realizados',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Header con estadísticas
                _buildEstadisticasHeader(pagosUsuario),
                const SizedBox(height: 8),

                // Lista de pagos
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _cargarPagosUsuario(),
                    child: ListView.builder(
                      itemCount: pagosUsuario.length,
                      itemBuilder: (context, index) {
                        final pago = pagosUsuario[index];
                        return PagoCardWidget(pago: pago);
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildEstadisticasHeader(List<Map<String, dynamic>> pagos) {
    final total = pagos.length;
    final completados = pagos.where((pago) {
      final estado = pago['estado_pago']?.toString() ?? '';
      return estado.toLowerCase() == 'completado';
    }).length;

    final pendientes = pagos.where((pago) {
      final estado = pago['estado_pago']?.toString() ?? '';
      return estado.toLowerCase() == 'pendiente';
    }).length;

    final montoTotal = pagos.fold<double>(0, (sum, pago) {
      final monto = pago['monto'] != null
          ? double.tryParse(pago['monto'].toString())
          : 0.0;
      return sum + (monto ?? 0.0);
    });

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', total.toString(), Icons.list),
            _buildStatItem(
                'Completados', completados.toString(), Icons.check_circle,
                color: Colors.green),
            _buildStatItem('Pendientes', pendientes.toString(), Icons.pending,
                color: Colors.orange),
            _buildStatItem('Monto Total', '\$${montoTotal.toStringAsFixed(2)}',
                Icons.attach_money,
                color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {Color color = Colors.blue}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
