// screens/pago_screen.dart - VERSIÓN CORREGIDA
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

class _PagoScreenState extends State<PagoScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<MercadoPagoCubit>().cargarHistorial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

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
        title: const Text('Gestión de Pagos'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20), // Icono más pequeño
            onPressed: () => cubit.cargarHistorial(),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20), // Icono más pequeño
            onPressed: _mostrarCrearPago,
            tooltip: 'Crear pago',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48), // TabBar más compacto
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold), // Texto más pequeño
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: const [
              Tab(icon: Icon(Icons.list, size: 18), text: 'Todos'),
              Tab(icon: Icon(Icons.pending, size: 18), text: 'Pendientes'),
              Tab(
                  icon: Icon(Icons.check_circle, size: 18),
                  text: 'Completados'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Buscador más compacto
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                isDense: true, // Hace el campo más compacto
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Buscar...',
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) => cubit.filtrarPagos(valor),
            ),
          ),

          // 📋 Lista de pagos
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListaPagosFiltrados(null),
                _buildListaPagosFiltrados('pendiente'),
                _buildListaPagosFiltrados('completado'),
              ],
            ),
          ),
        ],
      ),
    );
  }

// En pago_screen.dart - agregar este método
  Widget _buildEstadisticasHeader(List<Map<String, dynamic>> pagos) {
    final total = pagos.length;
    final pendientes =
        pagos.where((p) => p['estado_pago'] == 'pendiente').length;
    final completados =
        pagos.where((p) => p['estado_pago'] == 'completado').length;
    final montoTotal = pagos.fold<double>(0, (sum, pago) {
      final monto = pago['monto'] != null
          ? double.tryParse(pago['monto'].toString())
          : 0.0;
      return sum + (monto ?? 0.0);
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.teal[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStatItem('Total', total.toString()),
          _buildMiniStatItem('Pendientes', pendientes.toString()),
          _buildMiniStatItem('Completados', completados.toString()),
          _buildMiniStatItem('Monto', '\$${montoTotal.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildMiniStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildListaPagosFiltrados(String? estadoFiltro) {
    return BlocBuilder<MercadoPagoCubit, MercadoPagoState>(
      builder: (context, state) {
        if (state is MercadoPagoLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MercadoPagoError) {
          return Center(
            child: Padding(
              // ✅ AGREGAR PADDING PARA EVITAR OVERFLOW
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ EVITAR QUE CRECZA DEMASIADO
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MercadoPagoCubit>().cargarHistorial(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is MercadoPagoLoaded) {
          List<Map<String, dynamic>> pagosFiltrados = state.pagosFiltrados;

          // Aplicar filtro adicional por estado si es necesario
          if (estadoFiltro != null) {
            pagosFiltrados = pagosFiltrados.where((pago) {
              final estado =
                  pago['estado_pago']?.toString().toLowerCase() ?? '';
              return estado == estadoFiltro.toLowerCase();
            }).toList();
          }

          if (pagosFiltrados.isEmpty) {
            return Center(
              child: Padding(
                // ✅ AGREGAR PADDING
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ✅ EVITAR OVERFLOW
                  children: [
                    Icon(
                      _getEmptyStateIcon(estadoFiltro),
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getEmptyStateMessage(estadoFiltro),
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<MercadoPagoCubit>().cargarHistorial(),
            child: ListView.builder(
              itemCount: pagosFiltrados.length,
              itemBuilder: (context, index) {
                final pago = pagosFiltrados[index];
                return PagoCardWidget(pago: pago);
              },
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  IconData _getEmptyStateIcon(String? estadoFiltro) {
    switch (estadoFiltro) {
      case 'pendiente':
        return Icons.pending_actions;
      case 'completado':
        return Icons.check_circle_outline;
      default:
        return Icons.payment;
    }
  }

  String _getEmptyStateMessage(String? estadoFiltro) {
    switch (estadoFiltro) {
      case 'pendiente':
        return 'No hay pagos pendientes';
      case 'completado':
        return 'No hay pagos completados';
      default:
        return 'No hay pagos registrados';
    }
  }
}
