// screens/inscripciones_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Cubits/inscripcion_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';
import '../widgets/inscripcion_card_widget.dart';
import '../widgets/filtros_inscripcion_widget.dart';
import '../widgets/crear_inscripcion_widget.dart';

class InscripcionesScreen extends StatefulWidget {
  const InscripcionesScreen({Key? key}) : super(key: key);

  @override
  State<InscripcionesScreen> createState() => _InscripcionesScreenState();
}

class _InscripcionesScreenState extends State<InscripcionesScreen> {
  @override
  void initState() {
    super.initState();
    _cargarInscripciones();
  }

  void _cargarInscripciones() {
    final cubit = context.read<InscripcionCubit>();
    cubit.cargarInscripciones();
  }

  void _aplicarFiltros(Map<String, dynamic> filtros) {
    final cubit = context.read<InscripcionCubit>();
    cubit.cargarInscripciones(
      estado: filtros['estado'],
      clienteDni: filtros['clienteDni'],
      fechaInicio: filtros['fechaInicio'],
      fechaFin: filtros['fechaFin'],
    );

    if (filtros['query'] != null && filtros['query'].isNotEmpty) {
      cubit.filtrarInscripciones(filtros['query']);
    }
  }

  void _mostrarDialogoCrearInscripcion() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CrearInscripcionWidget(
            onGuardar: (datosInscripcion) async {
              final cubit = context.read<InscripcionCubit>();
              await cubit.crearInscripcion(datosInscripcion);
              if (mounted) Navigator.of(context).pop();
            },
            onCancelar: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _mostrarReportes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildPanelReportes(),
    );
  }

  Widget _buildPanelReportes() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          const Text(
            'Reportes de Inscripciones',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildBotonReporte(
                  icon: Icons.people,
                  titulo: 'Clases Más Populares',
                  onTap: _generarReporteClasesPopulares,
                ),
                _buildBotonReporte(
                  icon: Icons.star,
                  titulo: 'Clientes Más Activos',
                  onTap: _generarReporteClientesActivos,
                ),
                _buildBotonReporte(
                  icon: Icons.warning,
                  titulo: 'Alertas de Cupos Críticos',
                  onTap: _mostrarAlertasCuposCriticos,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonReporte({
    required IconData icon,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(titulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _generarReporteClasesPopulares() async {
    final cubit = context.read<InscripcionCubit>();
    try {
      final reporte = await cubit.generarReporteClasesPopulares();
      _mostrarReporteDialog('Clases Más Populares', reporte);
    } catch (e) {
      _mostrarMensaje('Error al generar reporte: $e', esError: true);
    }
  }

  Future<void> _generarReporteClientesActivos() async {
    final cubit = context.read<InscripcionCubit>();
    try {
      final reporte = await cubit.generarReporteClientesActivos();
      _mostrarReporteDialog('Clientes Más Activos', reporte);
    } catch (e) {
      _mostrarMensaje('Error al generar reporte: $e', esError: true);
    }
  }

  Future<void> _mostrarAlertasCuposCriticos() async {
    final cubit = context.read<InscripcionCubit>();
    try {
      final alertas = await cubit.obtenerAlertasCuposCriticos();
      _mostrarReporteDialog('Alertas de Cupos Críticos', alertas);
    } catch (e) {
      _mostrarMensaje('Error al obtener alertas: $e', esError: true);
    }
  }

  void _mostrarReporteDialog(String titulo, dynamic datos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 400,
          child: _buildContenidoReporte(datos),
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

  Widget _buildContenidoReporte(dynamic datos) {
    if (datos is List && datos.isEmpty) {
      return const Text('No hay datos para mostrar');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: datos.length,
      itemBuilder: (context, index) {
        final item = datos[index] as Map<String, dynamic>;
        return ListTile(
          title: Text(item['nombre']?.toString() ?? 'Sin nombre'),
          subtitle: Text('Cantidad: ${item['cantidad'] ?? '0'}'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inscripciones'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarInscripciones,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _mostrarReportes,
            tooltip: 'Reportes',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          FiltrosInscripcionWidget(onFiltrosCambiados: _aplicarFiltros),

          // Lista de inscripciones
          Expanded(
            child: BlocBuilder<InscripcionCubit, InscripcionState>(
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
                          onPressed: _cargarInscripciones,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is InscripcionLoaded) {
                  final inscripciones = state.inscripcionesFiltradas;

                  if (inscripciones.isEmpty) {
                    return const Center(
                        child: Text('No hay inscripciones disponibles'));
                  }

                  return ListView.builder(
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
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearInscripcion,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _cancelarInscripcion(Map<String, dynamic> inscripcion) async {
    final motivo = await _mostrarDialogoMotivo('Cancelar Inscripción');
    if (motivo != null && motivo.isNotEmpty) {
      final cubit = context.read<InscripcionCubit>();
      try {
        await cubit.cancelarInscripcion(inscripcion['id'] as int, motivo);
        _mostrarMensaje('Inscripción cancelada exitosamente');
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
            children: [
              _buildDetalleItem('ID', inscripcion['id']?.toString() ?? 'N/A'),
              _buildDetalleItem('Cliente',
                  inscripcion['nombre_cliente']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Email', inscripcion['email_cliente']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Clase', inscripcion['clase_nombre']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Estado', inscripcion['estado']?.toString() ?? 'N/A'),
              _buildDetalleItem('Fecha',
                  inscripcion['fecha_inscripcion']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Precio', '\$${inscripcion['precio']?.toString() ?? 'N/A'}'),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$titulo: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    AppSnackBar.show(context, mensaje, error: esError);
  }
}
