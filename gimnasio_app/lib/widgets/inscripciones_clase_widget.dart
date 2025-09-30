// widgets/inscripciones_clase_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Cubits/inscripcion_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class InscripcionesClaseWidget extends StatefulWidget {
  final Map<String, dynamic> clase;
  final VoidCallback onCerrar;

  const InscripcionesClaseWidget({
    Key? key,
    required this.clase,
    required this.onCerrar,
  }) : super(key: key);

  @override
  State<InscripcionesClaseWidget> createState() =>
      _InscripcionesClaseWidgetState();
}

class _InscripcionesClaseWidgetState extends State<InscripcionesClaseWidget> {
  List<dynamic> _inscripciones = [];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarInscripciones();
  }

  void _cargarInscripciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final cubit = context.read<InscripcionCubit>();

      // Cargar todas las inscripciones filtradas por la clase
      await cubit.cargarInscripciones(claseId: widget.clase['id'] as int);

      // En el estado loaded, obtenemos las inscripciones filtradas
      final state = cubit.state;
      if (state is InscripcionLoaded) {
        setState(() {
          _inscripciones = state.inscripcionesFiltradas;
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  void _cancelarInscripcion(int inscripcionId) async {
    final motivo = await _mostrarDialogoMotivoCancelacion();
    if (motivo != null && motivo.isNotEmpty) {
      final cubit = context.read<InscripcionCubit>();
      try {
        await cubit.cancelarInscripcion(inscripcionId, motivo);
        // Recargar la lista después de cancelar
        _cargarInscripciones();

        if (mounted) {
          AppSnackBar.show(context, 'Inscripción cancelada exitosamente');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(context, 'Error al cancelar inscripción: $e',
              error: true);
        }
      }
    }
  }

  Future<String?> _mostrarDialogoMotivoCancelacion() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Inscripción'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Motivo de cancelación',
            border: OutlineInputBorder(),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscripciones - ${widget.clase['nombre']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarInscripciones,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCerrar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildInscripcionesList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarInscripciones,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInscripcionesList() {
    return Column(
      children: [
        _buildEstadisticasHeader(_inscripciones),
        Expanded(
          child: _inscripciones.isEmpty
              ? const Center(
                  child: Text('No hay inscripciones para esta clase'))
              : ListView.builder(
                  itemCount: _inscripciones.length,
                  itemBuilder: (context, index) {
                    final inscripcion =
                        _inscripciones[index] as Map<String, dynamic>;
                    return _buildInscripcionItem(inscripcion);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasHeader(List<dynamic> inscripciones) {
    final inscripcionesActivas = inscripciones.where((insc) {
      final estado = (insc as Map<String, dynamic>)['estado']?.toString() ?? '';
      return estado.toLowerCase() == 'activa';
    }).length;

    final capacidad = widget.clase['capacidad'] as int? ?? 0;
    final porcentajeOcupacion = capacidad > 0
        ? (inscripcionesActivas / capacidad * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', inscripciones.length.toString()),
            _buildStatItem('Activas', inscripcionesActivas.toString()),
            _buildStatItem('Capacidad', capacidad.toString()),
            _buildStatItem('Ocupación', '$porcentajeOcupacion%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInscripcionItem(Map<String, dynamic> inscripcion) {
    final nombre = inscripcion['nombre_cliente']?.toString() ?? 'Cliente';
    final email = inscripcion['email_cliente']?.toString() ?? 'Sin email';
    final estado = inscripcion['estado']?.toString() ?? 'Desconocido';
    final fechaInscripcion = inscripcion['fecha_inscripcion']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C'),
        ),
        title: Text(nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            if (fechaInscripcion.isNotEmpty)
              Text('Inscrito: $fechaInscripcion',
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                estado,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getColorEstado(estado),
            ),
            if (estado.toLowerCase() == 'activa')
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _cancelarInscripcion(inscripcion['id'] as int),
                tooltip: 'Cancelar inscripción',
              ),
          ],
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'activa':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'completada':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
