// screens/usuario_detail_screen.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/usuario_cubit.dart';
import 'package:gimnasio_app/Cubits/inscripcion_cubit.dart';
import 'package:gimnasio_app/Cubits/mercado_pago_cubit.dart';
import 'package:gimnasio_app/Screens/usuario_inscripciones_screen.dart';
import 'package:gimnasio_app/Screens/usuario_pagos_screen.dart';
import 'package:gimnasio_app/Widgets/crear_usuario_widget.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class UsuarioDetailScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const UsuarioDetailScreen({super.key, required this.usuario});

  @override
  State<UsuarioDetailScreen> createState() => _UsuarioDetailScreenState();
}

class _UsuarioDetailScreenState extends State<UsuarioDetailScreen> {
  Map<String, dynamic>? _detalleCompleto;
  int _totalInscripciones = 0;
  int _totalPagos = 0;
  bool _cargandoEstadisticas = false;

  @override
  void initState() {
    super.initState();
    _cargarDetalleCompleto();
    _cargarEstadisticas();
  }

  void _cargarDetalleCompleto() async {
    try {
      final detalle = await context
          .read<UsuarioCubit>()
          .obtenerDetalle(widget.usuario['id'] as int);
      setState(() {
        _detalleCompleto = detalle;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error cargando detalles: ${e.toString()}',
            error: true);
      }
    }
  }

  void _cargarEstadisticas() async {
    if (_cargandoEstadisticas) return;

    setState(() {
      _cargandoEstadisticas = true;
    });

    try {
      final dni = widget.usuario['dni']?.toString();
      if (dni == null) return;

      // Cargar inscripciones del usuario
      final inscripcionCubit = context.read<InscripcionCubit>();
      await inscripcionCubit.cargarInscripciones(clienteDni: dni);

      // Cargar pagos del usuario
      final mercadoPagoCubit = context.read<MercadoPagoCubit>();
      await mercadoPagoCubit.cargarHistorial();

      // Calcular estadísticas
      if (mounted) {
        _calcularEstadisticas(inscripcionCubit, mercadoPagoCubit);
      }
    } catch (e) {
      if (mounted) {
        print('Error cargando estadísticas: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoEstadisticas = false;
        });
      }
    }
  }

  void _calcularEstadisticas(
      InscripcionCubit inscripcionCubit, MercadoPagoCubit mercadoPagoCubit) {
    final dni = widget.usuario['dni']?.toString();
    if (dni == null) return;

    // Calcular inscripciones
    int inscripcionesCount = 0;
    if (inscripcionCubit.state is InscripcionLoaded) {
      final state = inscripcionCubit.state as InscripcionLoaded;
      inscripcionesCount = state.inscripcionesFiltradas
          .where((inscripcion) => inscripcion['cliente_dni']?.toString() == dni)
          .length;
    }

    // Calcular pagos
    int pagosCount = 0;
    if (mercadoPagoCubit.state is MercadoPagoLoaded) {
      final state = mercadoPagoCubit.state as MercadoPagoLoaded;
      pagosCount = state.pagosFiltrados
          .where((pago) => pago['id_usuario']?.toString() == dni)
          .length;
    }

    setState(() {
      _totalInscripciones = inscripcionesCount;
      _totalPagos = pagosCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle: ${widget.usuario['nombre']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                    child: CrearUsuarioWidget(usuarioInicial: widget.usuario)),
              ).then((_) => _cargarDetalleCompleto());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarDetalleCompleto();
              _cargarEstadisticas();
            },
          ),
        ],
      ),
      body: _detalleCompleto == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tarjeta de información principal
                  _buildInfoCard(),
                  const SizedBox(height: 16),

                  // Acciones rápidas
                  _buildQuickActions(context),
                  const SizedBox(height: 16),

                  // Estadísticas REALES
                  _buildStatsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    final usuario = _detalleCompleto ?? widget.usuario;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar y estado
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color:
                        (usuario['activo'] == true ? Colors.green : Colors.red)
                            .withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color:
                        usuario['activo'] == true ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario['nombre'] ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: usuario['activo'] == true
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          usuario['activo'] == true ? 'ACTIVO' : 'INACTIVO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Información detallada
            _buildInfoRow('DNI', usuario['dni'] ?? 'N/A'),
            _buildInfoRow('Correo', usuario['correo'] ?? 'N/A'),
            _buildInfoRow('Teléfono', usuario['telefono'] ?? 'N/A'),
            _buildInfoRow('Ciudad', usuario['ciudad'] ?? 'No especificada'),
            if (usuario['fecha_nacimiento'] != null)
              _buildInfoRow(
                  'Fecha Nac.', _formatDate(usuario['fecha_nacimiento'])),
            if (usuario['fecha_registro'] != null)
              _buildInfoRow(
                  'Fecha Registro', _formatDate(usuario['fecha_registro'])),
            if (usuario['genero'] != null)
              _buildInfoRow('Género', usuario['genero']),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.assignment,
                  label: 'Inscripciones',
                  color: Colors.orange,
                  onTap: () => _navigateToInscripciones(context),
                ),
                _buildActionButton(
                  icon: Icons.payment,
                  label: 'Pagos',
                  color: Colors.teal,
                  onTap: () => _navigateToPagos(context),
                ),
                _buildActionButton(
                  icon: Icons.history,
                  label: 'Transacciones',
                  color: Colors.indigo,
                  onTap: () => _navigateToTransacciones(context),
                ),
                _buildActionButton(
                  icon: widget.usuario['activo'] == true
                      ? Icons.person_off
                      : Icons.person,
                  label: widget.usuario['activo'] == true
                      ? 'Desactivar'
                      : 'Activar',
                  color: widget.usuario['activo'] == true
                      ? Colors.red
                      : Colors.green,
                  onTap: () => _toggleActivo(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cargandoEstadisticas) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _cargandoEstadisticas ? null : _cargarEstadisticas,
                  tooltip: 'Actualizar estadísticas',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Inscripciones', _totalInscripciones.toString(),
                    Icons.assignment),
                _buildStatItem('Pagos', _totalPagos.toString(), Icons.payment),
                _buildStatItem(
                    'Clases', '0', Icons.fitness_center), // Por ahora fijo
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateStr = date.toString();
      return dateStr.split('T').first;
    } catch (e) {
      return date.toString();
    }
  }

  void _navigateToInscripciones(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioInscripcionesScreen(usuario: widget.usuario),
      ),
    );
  }

  void _navigateToPagos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioPagosScreen(usuario: widget.usuario),
      ),
    );
  }

  void _navigateToTransacciones(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Navegando a transacciones de ${widget.usuario['nombre']}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleActivo(BuildContext context) async {
    final cubit = context.read<UsuarioCubit>();
    try {
      if (widget.usuario['activo'] == true) {
        await cubit.desactivarUsuario(widget.usuario['id'] as int);
        if (mounted) {
          AppSnackBar.show(context, 'Usuario desactivado correctamente');
        }
      } else {
        await cubit.activarUsuario(widget.usuario['id'] as int);
        if (mounted) {
          AppSnackBar.show(context, 'Usuario activado correctamente');
        }
      }
      // Recargar detalles y estadísticas
      _cargarDetalleCompleto();
      _cargarEstadisticas();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: ${e.toString()}', error: true);
      }
    }
  }
}
