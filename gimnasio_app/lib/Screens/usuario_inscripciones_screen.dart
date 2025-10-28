// screens/usuario_inscripciones_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Cubits/inscripcion_cubit.dart';
import '../widgets/inscripcion_card_widget.dart';
import '../utils/snackbars.dart';

class UsuarioInscripcionesScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const UsuarioInscripcionesScreen({super.key, required this.usuario});

  @override
  State<UsuarioInscripcionesScreen> createState() =>
      _UsuarioInscripcionesScreenState();
}

class _UsuarioInscripcionesScreenState
    extends State<UsuarioInscripcionesScreen> {
  @override
  void initState() {
    super.initState();
    _cargarInscripcionesUsuario();
  }

  void _cargarInscripcionesUsuario() {
    final cubit = context.read<InscripcionCubit>();
    cubit.cargarInscripciones(clienteDni: widget.usuario['dni']?.toString());
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    AppSnackBar.show(context, mensaje, error: esError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscripciones de ${widget.usuario['nombre']}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarInscripcionesUsuario,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: BlocBuilder<InscripcionCubit, InscripcionState>(
        builder: (context, state) {
          if (state is InscripcionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InscripcionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarInscripcionesUsuario,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is InscripcionLoaded) {
            final inscripciones = state.inscripcionesFiltradas;

            if (inscripciones.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay inscripciones',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.usuario['nombre']} no tiene inscripciones activas',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Header con estadísticas
                _buildEstadisticasHeader(inscripciones),
                const SizedBox(height: 8),

                // Lista de inscripciones
                Expanded(
                  child: ListView.builder(
                    itemCount: inscripciones.length,
                    itemBuilder: (context, index) {
                      final inscripcion =
                          inscripciones[index] as Map<String, dynamic>;
                      return InscripcionCardWidget(
                        inscripcion: inscripcion,
                        onCancelar: () => _cancelarInscripcion(inscripcion),
                        onReactivar: () => _reactivarInscripcion(inscripcion),
                        onCompletar: () => _completarInscripcion(inscripcion),
                        onVerDetalles: () =>
                            _verDetallesInscripcion(inscripcion),
                      );
                    },
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

  Widget _buildEstadisticasHeader(List<dynamic> inscripciones) {
    final total = inscripciones.length;
    final activas = inscripciones.where((insc) {
      final estado = (insc as Map<String, dynamic>)['estado']?.toString() ?? '';
      return estado.toLowerCase() == 'activo' ||
          estado.toLowerCase() == 'activa';
    }).length;

    final completadas = inscripciones.where((insc) {
      final estado = (insc as Map<String, dynamic>)['estado']?.toString() ?? '';
      return estado.toLowerCase() == 'completado' ||
          estado.toLowerCase() == 'completada';
    }).length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', total.toString(), Icons.assignment),
            _buildStatItem('Activas', activas.toString(), Icons.check_circle,
                color: Colors.green),
            _buildStatItem(
                'Completadas', completadas.toString(), Icons.verified,
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

  // ==================== MÉTODOS DE GESTIÓN ====================
  Future<void> _cancelarInscripcion(Map<String, dynamic> inscripcion) async {
    final motivo = await _mostrarDialogoMotivo('Cancelar Inscripción');
    if (motivo != null && motivo.isNotEmpty) {
      final cubit = context.read<InscripcionCubit>();
      try {
        await cubit.cancelarInscripcion(inscripcion['id'] as int, motivo);
        _mostrarMensaje('Inscripción cancelada exitosamente');
        _cargarInscripcionesUsuario(); // Recargar lista
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  Future<void> _reactivarInscripcion(Map<String, dynamic> inscripcion) async {
    final confirmado = await _mostrarDialogoConfirmacion(
      'Reactivar Inscripción',
      '¿Estás seguro de reactivar esta inscripción?',
    );
    if (confirmado) {
      final cubit = context.read<InscripcionCubit>();
      try {
        await cubit.reactivarInscripcion(inscripcion['id'] as int);
        _mostrarMensaje('Inscripción reactivada exitosamente');
        _cargarInscripcionesUsuario(); // Recargar lista
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  Future<void> _completarInscripcion(Map<String, dynamic> inscripcion) async {
    final confirmado = await _mostrarDialogoConfirmacion(
      'Completar Inscripción',
      '¿Marcar esta inscripción como completada?',
    );
    if (confirmado) {
      final cubit = context.read<InscripcionCubit>();
      try {
        await cubit.completarInscripcion(inscripcion['id'] as int);
        _mostrarMensaje('Inscripción completada exitosamente');
        _cargarInscripcionesUsuario(); // Recargar lista
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  void _verDetallesInscripcion(Map<String, dynamic> inscripcion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Inscripción'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('ID', inscripcion['id']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Clase', inscripcion['clase_nombre']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Estado', inscripcion['estado']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Pagado', inscripcion['pagado'] == true ? 'Sí' : 'No'),
              _buildDetalleItem('Fecha Inscripción',
                  inscripcion['fecha_inscripcion']?.toString() ?? 'N/A'),
              if (inscripcion['fecha_cancelacion'] != null)
                _buildDetalleItem('Fecha Cancelación',
                    inscripcion['fecha_cancelacion']?.toString() ?? 'N/A'),
              if (inscripcion['motivo_cancelacion'] != null)
                _buildDetalleItem('Motivo Cancelación',
                    inscripcion['motivo_cancelacion']?.toString() ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$titulo:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  Future<String?> _mostrarDialogoMotivo(String titulo) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
            hintText: 'Ingrese el motivo...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _mostrarDialogoConfirmacion(
      String titulo, String mensaje) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
