// screens/clase_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/clase_cubit.dart';
import 'package:gimnasio_app/widgets/clase_form_widget.dart';
import 'package:gimnasio_app/widgets/clase_list_widget.dart';
import 'package:gimnasio_app/widgets/clase_stats_widget.dart';
import 'package:gimnasio_app/widgets/reportes_clase_widget.dart';
import 'package:gimnasio_app/widgets/inscripciones_clase_widget.dart';
import 'package:gimnasio_app/widgets/reporte_detalle_widget.dart';

class ClaseScreen extends StatefulWidget {
  const ClaseScreen({Key? key}) : super(key: key);

  @override
  State<ClaseScreen> createState() => _ClaseScreenState();
}

class _ClaseScreenState extends State<ClaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filtroEstado = 'todas';
  String _filtroDificultad = 'todas';
  String _filtroInstructor = 'todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _cargarClases();
  }

  void _cargarClases() {
    context.read<ClaseCubit>().cargarClases();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _aplicarFiltros() {
    context.read<ClaseCubit>().filtrarClases(
          nombre:
              _searchController.text.isEmpty ? null : _searchController.text,
          soloActivas: _filtroEstado == 'activas'
              ? true
              : (_filtroEstado == 'inactivas' ? false : null),
          dificultad: _filtroDificultad == 'todas' ? null : _filtroDificultad,
          instructor: _filtroInstructor == 'todos' ? null : _filtroInstructor,
        );
  }

  void _mostrarDialogoCrearClase() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Crear Nueva Clase',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ClaseFormWidget(
                    onGuardar: (datosClase) async {
                      await context.read<ClaseCubit>().crearClase(datosClase);
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clases'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarClases,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reporte_ocupacion':
                  _mostrarReporteOcupacion();
                  break;
                case 'reporte_dificultad':
                  _mostrarReporteDificultad();
                  break;
                case 'reporte_instructores':
                  _mostrarReporteInstructores();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'reporte_ocupacion', child: Text('Reporte Ocupación')),
              const PopupMenuItem(
                  value: 'reporte_dificultad',
                  child: Text('Reporte Dificultad')),
              const PopupMenuItem(
                  value: 'reporte_instructores',
                  child: Text('Reporte Instructores')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'duplicar_masivo',
                  child: Text('Duplicar Múltiples Clases')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Todas las Clases'),
            Tab(icon: Icon(Icons.check_circle), text: 'Activas'),
            Tab(icon: Icon(Icons.pending), text: 'Inactivas'),
            Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
            Tab(icon: Icon(Icons.assignment), text: 'Reportes'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros avanzados
          _buildFiltrosAvanzados(),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña 1: Todas las clases
                _buildListaClases(),

                // Pestaña 2: Clases activas
                _buildClasesActivas(),

                // Pestaña 3: Clases inactivas
                _buildClasesInactivas(),

                // Pestaña 4: Estadísticas
                _buildEstadisticas(),

                // Pestaña 5: Reportes
                _buildReportes(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearClase,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltrosAvanzados() {
    return BlocBuilder<ClaseCubit, ClaseState>(
      builder: (context, state) {
        if (state is! ClaseLoaded) return Container();

        final cubit = context.read<ClaseCubit>();
        final instructores = cubit.obtenerInstructoresUnicos();

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre de clase...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _aplicarFiltros();
                      },
                    ),
                  ),
                  onChanged: (_) => _aplicarFiltros(),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildFiltroDropdown(
                      value: _filtroEstado,
                      items: const [
                        DropdownMenuItem(
                            value: 'todas', child: Text('Todas las clases')),
                        DropdownMenuItem(
                            value: 'activas', child: Text('Solo activas')),
                        DropdownMenuItem(
                            value: 'inactivas', child: Text('Solo inactivas')),
                      ],
                      onChanged: (value) {
                        setState(() => _filtroEstado = value!);
                        _aplicarFiltros();
                      },
                      label: 'Estado',
                    ),
                    _buildFiltroDropdown(
                      value: _filtroDificultad,
                      items: const [
                        DropdownMenuItem(
                            value: 'todas',
                            child: Text('Todas las dificultades')),
                        DropdownMenuItem(
                            value: 'principiante', child: Text('Principiante')),
                        DropdownMenuItem(
                            value: 'intermedio', child: Text('Intermedio')),
                        DropdownMenuItem(
                            value: 'avanzado', child: Text('Avanzado')),
                      ],
                      onChanged: (value) {
                        setState(() => _filtroDificultad = value!);
                        _aplicarFiltros();
                      },
                      label: 'Dificultad',
                    ),
                    _buildFiltroDropdown(
                      value: _filtroInstructor,
                      items: [
                        const DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos los instructores')),
                        ...instructores.map((instructor) => DropdownMenuItem(
                            value: instructor, child: Text(instructor))),
                      ],
                      onChanged: (value) {
                        setState(() => _filtroInstructor = value!);
                        _aplicarFiltros();
                      },
                      label: 'Instructor',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltroDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildListaClases() {
    return BlocBuilder<ClaseCubit, ClaseState>(
      builder: (context, state) {
        if (state is ClaseLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ClaseError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text('Error: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cargarClases,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is ClaseLoaded) {
          return ClaseListWidget(
            clases: state.clasesFiltradas,
            onEditarClase: (clase) => _editarClase(clase),
            onActivarClase: (clase) => _activarClase(clase),
            onDesactivarClase: (clase) => _desactivarClase(clase),
            onDuplicarClase: (clase) => _duplicarClase(clase),
            onVerInscripciones: (clase) => _verInscripciones(clase),
            onVerEstadisticas: (clase) => _verEstadisticasClase(clase),
            onVerDetalles: (clase) => _verDetallesClase(clase),
          );
        }

        return const Center(child: Text('No hay datos disponibles'));
      },
    );
  }

  Widget _buildClasesActivas() {
    return BlocBuilder<ClaseCubit, ClaseState>(
      builder: (context, state) {
        if (state is ClaseLoaded) {
          final clasesActivas = state.clasesFiltradas
              .where((clase) => clase['activa'] == true)
              .toList()
              .cast<Map<String, dynamic>>();
          ;

          return ClaseListWidget(
            clases: clasesActivas,
            onEditarClase: _editarClase,
            onDesactivarClase: _desactivarClase,
            onDuplicarClase: _duplicarClase,
            onVerInscripciones: _verInscripciones,
            onVerEstadisticas: _verEstadisticasClase,
            onVerDetalles: _verDetallesClase,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildClasesInactivas() {
    return BlocBuilder<ClaseCubit, ClaseState>(
      builder: (context, state) {
        if (state is ClaseLoaded) {
          final clasesInactivas = state.clasesFiltradas
              .where((clase) => clase['activa'] == false)
              .toList()
              .cast<Map<String, dynamic>>();
          ;

          return ClaseListWidget(
            clases: clasesInactivas,
            onEditarClase: _editarClase,
            onActivarClase: _activarClase,
            onDuplicarClase: _duplicarClase,
            onVerInscripciones: _verInscripciones,
            onVerEstadisticas: _verEstadisticasClase,
            onVerDetalles: _verDetallesClase,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEstadisticas() {
    return BlocBuilder<ClaseCubit, ClaseState>(
      builder: (context, state) {
        if (state is ClaseLoaded) {
          return ClaseStatsWidget(
            clases: state.clasesFiltradas,
            onVerClase: _verDetallesClase,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildReportes() {
    return BlocBuilder<ClaseCubit, ClaseState>(
      builder: (context, state) {
        if (state is ClaseLoaded) {
          return ReportesClaseWidget(
            onGenerarReporteOcupacion: () async {
              final reporte =
                  await context.read<ClaseCubit>().generarReporteOcupacion();
              _mostrarReporteDialog('Reporte de Ocupación', reporte);
            },
            onGenerarReporteDificultad: () async {
              final reporte =
                  await context.read<ClaseCubit>().generarReporteDificultad();
              _mostrarReporteDialog('Reporte por Dificultad', reporte);
            },
            onGenerarReporteInstructores: () async {
              final reporte =
                  await context.read<ClaseCubit>().generarReporteInstructores();
              _mostrarReporteDialog('Reporte de Instructores', reporte);
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _editarClase(Map<String, dynamic> clase) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Editar ${clase['nombre']}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ClaseFormWidget(
                    clase: clase,
                    onGuardar: (datosActualizados) async {
                      await context
                          .read<ClaseCubit>()
                          .actualizarClase(clase['id'], datosActualizados);
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _activarClase(Map<String, dynamic> clase) async {
    final confirmado =
        await _mostrarDialogoConfirmacion('Activar Clase', '¿Estás seguro?');
    if (confirmado) {
      await context.read<ClaseCubit>().activarClase(clase['id']);
    }
  }

  void _desactivarClase(Map<String, dynamic> clase) async {
    final confirmado =
        await _mostrarDialogoConfirmacion('Desactivar Clase', '¿Estás seguro?');
    if (confirmado) {
      await context.read<ClaseCubit>().desactivarClase(clase['id']);
    }
  }

  void _duplicarClase(Map<String, dynamic> clase) async {
    final nuevoNombre = await _mostrarDialogoDuplicar(clase['nombre']);
    if (nuevoNombre != null && nuevoNombre.isNotEmpty) {
      await context.read<ClaseCubit>().duplicarClase(clase['id'], nuevoNombre);
    }
  }

  void _verInscripciones(Map<String, dynamic> clase) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: InscripcionesClaseWidget(
            clase: clase,
            onCerrar: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _verEstadisticasClase(Map<String, dynamic> clase) async {
    final cubit = context.read<ClaseCubit>();
    final estadisticas = await cubit.obtenerEstadisticasClase(clase['id']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estadísticas de ${clase['nombre'] ?? ''}'),
        content: SizedBox(
          width: 400,
          child: _buildEstadisticasClaseContent(estadisticas),
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

  Widget _buildEstadisticasClaseContent(Map<String, dynamic> estadisticas) {
    String porcentaje = '0.0';
    try {
      final p = estadisticas['ocupacion_porcentaje'];
      porcentaje = p != null ? (p as num).toStringAsFixed(1) : '0.0';
    } catch (_) {}

    String ingresos = '0.00';
    try {
      final ing = estadisticas['ingresos_totales'];
      ingresos = ing != null ? (ing as num).toStringAsFixed(2) : '0.00';
    } catch (_) {}

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatItem('Total Inscripciones',
            (estadisticas['total_inscripciones']?.toString() ?? '0')),
        _buildStatItem('Capacidad Ocupada', '$porcentaje%'),
        _buildStatItem('Inscripciones Activas',
            (estadisticas['inscripciones_activas']?.toString() ?? '0')),
        _buildStatItem('Ingresos Totales', '\\$${ingresos}'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _verDetallesClase(Map<String, dynamic> clase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${clase['nombre']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalleItem('ID', clase['id']?.toString() ?? ''),
              _buildDetalleItem('Nombre', clase['nombre']?.toString() ?? ''),
              _buildDetalleItem('Instructor',
                  clase['instructor']?.toString() ?? 'Sin instructor'),
              _buildDetalleItem('Dificultad',
                  clase['dificultad']?.toString() ?? 'Sin especificar'),
              _buildDetalleItem(
                  'Horario', clase['horario']?.toString() ?? 'No disponible'),
              _buildDetalleItem('Capacidad',
                  '${clase['capacidad']?.toString() ?? '0'} personas'),
              _buildDetalleItem('Duración',
                  '${clase['duracion_minutos']?.toString() ?? '0'} minutos'),
              _buildDetalleItem('Precio',
                  '\$${(clase['precio'] is num) ? (clase['precio'] as num).toStringAsFixed(2) : (clase['precio']?.toString() ?? '0.00')}'),
              _buildDetalleItem(
                  'Estado', (clase['activa'] == true) ? 'Activa' : 'Inactiva'),
              _buildDetalleItem('Descripción',
                  clase['descripcion']?.toString() ?? 'Sin descripción'),
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
          Text(
            '$titulo: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  Future<String?> _mostrarDialogoDuplicar(String nombreOriginal) async {
    final controller = TextEditingController(text: '$nombreOriginal (Copia)');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicar Clase'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nuevo nombre para la clase',
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
            child: const Text('Duplicar'),
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

  void _mostrarReporteOcupacion() async {
    final cubit = context.read<ClaseCubit>();
    final reporte = await cubit.generarReporteOcupacion();
    _mostrarReporteDialog('Reporte de Ocupación de Clases', reporte);
  }

  void _mostrarReporteDificultad() async {
    final cubit = context.read<ClaseCubit>();
    final reporte = await cubit.generarReporteDificultad();
    _mostrarReporteDialog('Reporte por Dificultad', reporte);
  }

  void _mostrarReporteInstructores() async {
    final cubit = context.read<ClaseCubit>();
    final reporte = await cubit.generarReporteInstructores();
    _mostrarReporteDialog('Reporte de Instructores', reporte);
  }

  void _mostrarReporteDialog(String titulo, dynamic reporte) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ReporteDetalleWidget(
            titulo: titulo,
            reporte: reporte,
            onCerrar: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
