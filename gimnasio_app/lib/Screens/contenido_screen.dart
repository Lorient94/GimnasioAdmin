// screens/contenido_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/contenido_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class ContenidoScreen extends StatefulWidget {
  const ContenidoScreen({Key? key}) : super(key: key);

  @override
  State<ContenidoScreen> createState() => _ContenidoScreenState();
}

class _ContenidoScreenState extends State<ContenidoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroCategoriaSeleccionada = 'todas';
  String _filtroTipoArchivoSeleccionado = 'todos';

  @override
  void initState() {
    super.initState();
    context.read<ContenidoCubit>().cargarContenidos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _mostrarDialogoCrearContenido() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _CrearContenidoWidget(
            onGuardar: (datosContenido) async {
              final cubit = context.read<ContenidoCubit>();
              await cubit.crearContenido(datosContenido);
              if (mounted) Navigator.of(context).pop();
            },
            onCancelar: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _editarContenido(Map<String, dynamic> contenido) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _EditarContenidoWidget(
            contenido: contenido,
            onGuardar: (datosActualizados) async {
              final cubit = context.read<ContenidoCubit>();
              await cubit.actualizarContenido(
                contenido['id'] as int,
                datosActualizados,
              );
              if (mounted) Navigator.of(context).pop();
            },
            onCancelar: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  // ========== MÉTODOS PARA FILTROS ==========

  Widget _buildPanelFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del panel de filtros
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Filtrar por:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Filtro por categoría
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Categoría:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categoriasFiltro.map((categoria) {
                return _buildBotonFiltroCategoria(categoria);
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Filtro por tipo de archivo
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Tipo de archivo:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tiposArchivoFiltro.map((tipo) {
                return _buildBotonFiltroTipoArchivo(tipo);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFiltroCategoria(String categoria) {
    final bool seleccionado = _filtroCategoriaSeleccionada == categoria;
    final String texto = _getTextoCategoria(categoria);
    final IconData icono = _getIconoCategoria(categoria);
    final Color color = _getColorCategoria(categoria);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16, color: seleccionado ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: seleccionado ? Colors.white : color,
              ),
            ),
          ],
        ),
        selected: seleccionado,
        onSelected: (bool selected) {
          setState(() {
            _filtroCategoriaSeleccionada = selected ? categoria : 'todas';
          });
          _aplicarFiltros();
        },
        backgroundColor: Colors.white,
        selectedColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildBotonFiltroTipoArchivo(String tipo) {
    final bool seleccionado = _filtroTipoArchivoSeleccionado == tipo;
    final String texto = _getTextoTipoArchivo(tipo);
    final IconData icono = _getIconoTipoArchivo(tipo);
    final Color color = _getColorTipoArchivo(tipo);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16, color: seleccionado ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: seleccionado ? Colors.white : color,
              ),
            ),
          ],
        ),
        selected: seleccionado,
        onSelected: (bool selected) {
          setState(() {
            _filtroTipoArchivoSeleccionado = selected ? tipo : 'todos';
          });
          _aplicarFiltros();
        },
        backgroundColor: Colors.white,
        selectedColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  String _getTextoCategoria(String categoria) {
    switch (categoria) {
      case 'todas':
        return 'Todas';
      case 'ejercicios':
        return 'Ejercicios';
      case 'nutricion':
        return 'Nutrición';
      case 'rutinas':
        return 'Rutinas';
      case 'salud':
        return 'Salud';
      case 'tecnica':
        return 'Técnica';
      case 'general':
        return 'General';
      default:
        return categoria;
    }
  }

  IconData _getIconoCategoria(String categoria) {
    switch (categoria) {
      case 'todas':
        return Icons.all_inclusive;
      case 'ejercicios':
        return Icons.fitness_center;
      case 'nutricion':
        return Icons.restaurant;
      case 'rutinas':
        return Icons.schedule;
      case 'salud':
        return Icons.health_and_safety;
      case 'tecnica':
        return Icons.sports;
      case 'general':
        return Icons.info;
      default:
        return Icons.category;
    }
  }

  Color _getColorCategoria(String categoria) {
    switch (categoria) {
      case 'todas':
        return Colors.blue;
      case 'ejercicios':
        return Colors.deepOrange;
      case 'nutricion':
        return Colors.green;
      case 'rutinas':
        return Colors.purple;
      case 'salud':
        return Colors.teal;
      case 'tecnica':
        return Colors.amber;
      case 'general':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _getTextoTipoArchivo(String tipo) {
    switch (tipo) {
      case 'todos':
        return 'Todos';
      case 'imagen':
        return 'Imágenes';
      case 'video':
        return 'Videos';
      case 'pdf':
        return 'PDF';
      case 'documento':
        return 'Documentos';
      case 'audio':
        return 'Audio';
      default:
        return tipo;
    }
  }

  IconData _getIconoTipoArchivo(String tipo) {
    switch (tipo) {
      case 'todos':
        return Icons.all_inclusive;
      case 'imagen':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'documento':
        return Icons.description;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorTipoArchivo(String tipo) {
    switch (tipo) {
      case 'todos':
        return Colors.blue;
      case 'imagen':
        return Colors.pink;
      case 'video':
        return Colors.red;
      case 'pdf':
        return Colors.deepOrange;
      case 'documento':
        return Colors.blueGrey;
      case 'audio':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _aplicarFiltros() {
    final cubit = context.read<ContenidoCubit>();

    if (_filtroCategoriaSeleccionada == 'todas' &&
        _filtroTipoArchivoSeleccionado == 'todos') {
      // Si es "todos", aplicar solo búsqueda
      cubit.filtrarLocalmente(_searchController.text);
    } else if (_filtroTipoArchivoSeleccionado == 'todos') {
      // Solo filtrar por categoría
      cubit.filtrarPorCategoria(
          _filtroCategoriaSeleccionada, _searchController.text);
    } else {
      // Aplicar filtros combinados
      cubit.filtrarPorCategoriaYTipo(
        _filtroCategoriaSeleccionada,
        _filtroTipoArchivoSeleccionado,
        _searchController.text,
      );
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroCategoriaSeleccionada = 'todas';
      _filtroTipoArchivoSeleccionado = 'todos';
      _searchController.clear();
    });
    context.read<ContenidoCubit>().cargarContenidos();
  }

  Widget _buildIndicadorFiltrosActivos() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getTextoIndicadorFiltros(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _limpiarFiltros,
            child: Row(
              children: [
                Text(
                  'Limpiar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.clear, size: 16, color: Colors.blue[700]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTextoIndicadorFiltros() {
    final List<String> filtros = [];

    if (_filtroCategoriaSeleccionada != 'todas') {
      filtros.add(
          'Categoría: ${_getTextoCategoria(_filtroCategoriaSeleccionada)}');
    }

    if (_filtroTipoArchivoSeleccionado != 'todos') {
      filtros
          .add('Tipo: ${_getTextoTipoArchivo(_filtroTipoArchivoSeleccionado)}');
    }

    if (_searchController.text.isNotEmpty) {
      filtros.add('Búsqueda: "${_searchController.text}"');
    }

    return filtros.join(' • ');
  }

  // ========== WIDGET PRINCIPAL ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Contenido'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          // Botón para limpiar filtros
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: _limpiarFiltros,
            tooltip: 'Limpiar filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ContenidoCubit>().cargarContenidos(),
            tooltip: 'Actualizar',
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
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por título, descripción o categoría...',
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _aplicarFiltros();
                        },
                      )
                    : null,
              ),
              onChanged: (value) => _aplicarFiltros(),
            ),
          ),

          // Panel de filtros
          _buildPanelFiltros(),

          // Indicador de filtro activo
          if (_filtroCategoriaSeleccionada != 'todas' ||
              _filtroTipoArchivoSeleccionado != 'todos' ||
              _searchController.text.isNotEmpty)
            _buildIndicadorFiltrosActivos(),

          // Lista de contenidos
          Expanded(
            child: BlocBuilder<ContenidoCubit, ContenidoState>(
              builder: (context, state) {
                if (state is ContenidoLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ContenidoError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ContenidoCubit>().cargarContenidos(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ContenidoLoaded) {
                  final contenidos = state.filtradas;

                  if (contenidos.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay contenido disponible',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para crear nuevo contenido',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: contenidos.length,
                    itemBuilder: (context, index) {
                      final contenido = contenidos[index];
                      return _ContenidoCard(
                        contenido: contenido,
                        onActivar: () => _activarContenido(contenido),
                        onDesactivar: () => _desactivarContenido(contenido),
                        onEliminar: () => _eliminarContenido(contenido),
                        onEditar: () => _editarContenido(contenido),
                        onVerDetalles: () => _verDetallesContenido(contenido),
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
        onPressed: _mostrarDialogoCrearContenido,
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ========== MÉTODOS DE GESTIÓN ==========

  Future<void> _activarContenido(Map<String, dynamic> contenido) async {
    final confirmado = await _mostrarDialogoConfirmacion(
      'Activar Contenido',
      '¿Estás seguro de activar este contenido?',
    );

    if (confirmado) {
      final cubit = context.read<ContenidoCubit>();
      try {
        await cubit.activarContenido(contenido['id'] as int);
        _mostrarMensaje('Contenido activado exitosamente');
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  Future<void> _desactivarContenido(Map<String, dynamic> contenido) async {
    final confirmado = await _mostrarDialogoConfirmacion(
      'Desactivar Contenido',
      '¿Estás seguro de desactivar este contenido?',
    );

    if (confirmado) {
      final cubit = context.read<ContenidoCubit>();
      try {
        await cubit.desactivarContenido(contenido['id'] as int);
        _mostrarMensaje('Contenido desactivado exitosamente');
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  Future<void> _eliminarContenido(Map<String, dynamic> contenido) async {
    final confirmado = await _mostrarDialogoConfirmacion(
      'Eliminar Contenido',
      '¿Estás seguro de eliminar permanentemente este contenido?',
    );

    if (confirmado) {
      final cubit = context.read<ContenidoCubit>();
      try {
        await cubit.desactivarContenido(contenido['id'] as int);
        _mostrarMensaje('Contenido eliminado exitosamente');
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  void _verDetallesContenido(Map<String, dynamic> contenido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Contenido'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalleItem('ID', contenido['id']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Título', contenido['titulo']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Categoría', contenido['categoria']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Descripción', contenido['descripcion']?.toString() ?? 'N/A'),
              _buildDetalleItem('Tipo Archivo',
                  contenido['tipo_archivo']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'URL Archivo', contenido['url_archivo']?.toString() ?? 'N/A'),
              _buildDetalleItem('Estado',
                  contenido['activo'] == true ? 'Activo' : 'Inactivo'),
              _buildDetalleItem(
                  'Público', contenido['es_publico'] == true ? 'Sí' : 'No'),
              _buildDetalleItem('Fecha Creación',
                  contenido['fecha_creacion']?.toString() ?? 'N/A'),
              if (contenido['fecha_actualizacion'] != null)
                _buildDetalleItem('Fecha Actualización',
                    contenido['fecha_actualizacion']?.toString() ?? 'N/A'),
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

// ========== WIDGETS AUXILIARES ==========

// Widget para tarjeta de contenido
class _ContenidoCard extends StatelessWidget {
  final Map<String, dynamic> contenido;
  final VoidCallback? onActivar;
  final VoidCallback? onDesactivar;
  final VoidCallback? onEliminar;
  final VoidCallback? onEditar;
  final VoidCallback? onVerDetalles;

  const _ContenidoCard({
    Key? key,
    required this.contenido,
    this.onActivar,
    this.onDesactivar,
    this.onEliminar,
    this.onEditar,
    this.onVerDetalles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titulo = contenido['titulo']?.toString() ?? 'Sin título';
    final categoria = contenido['categoria']?.toString() ?? 'Sin categoría';
    final tipoArchivo = contenido['tipo_archivo']?.toString() ?? 'Sin tipo';
    final activo = contenido['activo'] == true;
    final esPublico = contenido['es_publico'] == true;
    final descripcion = contenido['descripcion']?.toString() ?? '';
    final fechaCreacion = contenido['fecha_creacion']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activo ? Colors.green : Colors.grey,
          child: Icon(
            _getIconPorTipoArchivo(tipoArchivo),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: activo ? null : TextDecoration.lineThrough,
            )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '$categoria • $tipoArchivo • ${activo ? 'Activo' : 'Inactivo'}'),
            if (descripcion.isNotEmpty)
              Text(
                descripcion.length > 50
                    ? '${descripcion.substring(0, 50)}...'
                    : descripcion,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Row(
              children: [
                Icon(esPublico ? Icons.public : Icons.lock,
                    size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  esPublico ? 'Público' : 'Privado',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                if (fechaCreacion.isNotEmpty)
                  Text(
                    'Creado: $fechaCreacion',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                activo ? 'ACTIVO' : 'INACTIVO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: activo ? Colors.green : Colors.grey,
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuSelection(value, context),
              itemBuilder: (context) => _buildMenuItems(activo),
            ),
          ],
        ),
        onTap: onVerDetalles,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(bool activo) {
    final items = <PopupMenuEntry<String>>[];

    items.add(
        const PopupMenuItem(value: 'detalles', child: Text('Ver Detalles')));
    items.add(const PopupMenuItem(value: 'editar', child: Text('Editar')));

    if (activo) {
      items.add(
          const PopupMenuItem(value: 'desactivar', child: Text('Desactivar')));
    } else {
      items.add(const PopupMenuItem(value: 'activar', child: Text('Activar')));
    }

    items.add(const PopupMenuItem(
      value: 'eliminar',
      child: Text('Eliminar', style: TextStyle(color: Colors.red)),
    ));

    return items;
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'detalles':
        onVerDetalles?.call();
        break;
      case 'editar':
        onEditar?.call();
        break;
      case 'activar':
        onActivar?.call();
        break;
      case 'desactivar':
        onDesactivar?.call();
        break;
      case 'eliminar':
        onEliminar?.call();
        break;
    }
  }

  IconData _getIconPorTipoArchivo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'imagen':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'documento':
        return Icons.description;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }
}

// Widget para Crear Contenido (interno)
class _CrearContenidoWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onGuardar;
  final VoidCallback onCancelar;

  const _CrearContenidoWidget({
    Key? key,
    required this.onGuardar,
    required this.onCancelar,
  }) : super(key: key);

  @override
  State<_CrearContenidoWidget> createState() => __CrearContenidoWidgetState();
}

class __CrearContenidoWidgetState extends State<_CrearContenidoWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _urlArchivoController = TextEditingController();

  String _categoriaSeleccionada = 'general';
  String _tipoArchivoSeleccionado = 'documento';
  bool _activo = true;
  bool _esPublico = true;

  final List<String> _categorias = [
    'ejercicios',
    'nutricion',
    'rutinas',
    'salud',
    'tecnica',
    'general'
  ];

  final List<String> _tiposArchivo = [
    'imagen',
    'video',
    'pdf',
    'documento',
    'audio'
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _urlArchivoController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final datosContenido = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'categoria': _categoriaSeleccionada,
        'tipo_archivo': _tipoArchivoSeleccionado,
        'url_archivo': _urlArchivoController.text.trim(),
        'activo': _activo,
        'es_publico': _esPublico,
      };

      widget.onGuardar(datosContenido);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Contenido'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardar,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese el título del contenido',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(
                      _getTextoCategoria(categoria),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tipo de Archivo
              DropdownButtonFormField<String>(
                value: _tipoArchivoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Archivo *',
                  border: OutlineInputBorder(),
                ),
                items: _tiposArchivo.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(
                      _getTextoTipoArchivo(tipo),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoArchivoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // URL del Archivo
              TextFormField(
                controller: _urlArchivoController,
                decoration: const InputDecoration(
                  labelText: 'URL del Archivo *',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese la URL del archivo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La URL del archivo es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese la descripción del contenido',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Estado activo/inactivo
              SwitchListTile(
                title: const Text('Contenido Activo'),
                subtitle:
                    const Text('El contenido será visible para los usuarios'),
                value: _activo,
                onChanged: (value) {
                  setState(() {
                    _activo = value;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Estado público/privado
              SwitchListTile(
                title: const Text('Contenido Público'),
                subtitle: const Text(
                    'El contenido será accesible para todos los usuarios'),
                value: _esPublico,
                onChanged: (value) {
                  setState(() {
                    _esPublico = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancelar,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar Contenido'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTextoCategoria(String categoria) {
    switch (categoria) {
      case 'ejercicios':
        return 'Ejercicios';
      case 'nutricion':
        return 'Nutrición';
      case 'rutinas':
        return 'Rutinas';
      case 'salud':
        return 'Salud';
      case 'tecnica':
        return 'Técnica';
      case 'general':
        return 'General';
      default:
        return categoria;
    }
  }

  String _getTextoTipoArchivo(String tipo) {
    switch (tipo) {
      case 'imagen':
        return 'Imagen';
      case 'video':
        return 'Video';
      case 'pdf':
        return 'PDF';
      case 'documento':
        return 'Documento';
      case 'audio':
        return 'Audio';
      default:
        return tipo;
    }
  }
}

// Widget para Editar Contenido (interno)
class _EditarContenidoWidget extends StatefulWidget {
  final Map<String, dynamic> contenido;
  final Function(Map<String, dynamic>) onGuardar;
  final VoidCallback onCancelar;

  const _EditarContenidoWidget({
    Key? key,
    required this.contenido,
    required this.onGuardar,
    required this.onCancelar,
  }) : super(key: key);

  @override
  State<_EditarContenidoWidget> createState() => __EditarContenidoWidgetState();
}

class __EditarContenidoWidgetState extends State<_EditarContenidoWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _urlArchivoController;

  late String _categoriaSeleccionada;
  late String _tipoArchivoSeleccionado;
  late bool _activo;
  late bool _esPublico;

  final List<String> _categorias = [
    'ejercicios',
    'nutricion',
    'rutinas',
    'salud',
    'tecnica',
    'general'
  ];

  final List<String> _tiposArchivo = [
    'imagen',
    'video',
    'pdf',
    'documento',
    'audio'
  ];

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
        text: widget.contenido['titulo']?.toString() ?? '');
    _descripcionController = TextEditingController(
        text: widget.contenido['descripcion']?.toString() ?? '');
    _urlArchivoController = TextEditingController(
        text: widget.contenido['url_archivo']?.toString() ?? '');

    _categoriaSeleccionada =
        widget.contenido['categoria']?.toString() ?? 'general';
    _tipoArchivoSeleccionado =
        widget.contenido['tipo_archivo']?.toString() ?? 'documento';
    _activo = widget.contenido['activo'] == true;
    _esPublico = widget.contenido['es_publico'] == true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _urlArchivoController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final datosActualizados = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'categoria': _categoriaSeleccionada,
        'tipo_archivo': _tipoArchivoSeleccionado,
        'url_archivo': _urlArchivoController.text.trim(),
        'activo': _activo,
        'es_publico': _esPublico,
      };

      widget.onGuardar(datosActualizados);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Contenido'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardar,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(_getTextoCategoria(categoria)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tipo de Archivo
              DropdownButtonFormField<String>(
                value: _tipoArchivoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Archivo *',
                  border: OutlineInputBorder(),
                ),
                items: _tiposArchivo.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(_getTextoTipoArchivo(tipo)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoArchivoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // URL del Archivo
              TextFormField(
                controller: _urlArchivoController,
                decoration: const InputDecoration(
                  labelText: 'URL del Archivo *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La URL del archivo es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Estado activo/inactivo
              SwitchListTile(
                title: const Text('Contenido Activo'),
                subtitle:
                    const Text('El contenido será visible para los usuarios'),
                value: _activo,
                onChanged: (value) {
                  setState(() {
                    _activo = value;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Estado público/privado
              SwitchListTile(
                title: const Text('Contenido Público'),
                subtitle: const Text(
                    'El contenido será accesible para todos los usuarios'),
                value: _esPublico,
                onChanged: (value) {
                  setState(() {
                    _esPublico = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancelar,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar Cambios'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTextoCategoria(String categoria) {
    switch (categoria) {
      case 'ejercicios':
        return 'Ejercicios';
      case 'nutricion':
        return 'Nutrición';
      case 'rutinas':
        return 'Rutinas';
      case 'salud':
        return 'Salud';
      case 'tecnica':
        return 'Técnica';
      case 'general':
        return 'General';
      default:
        return categoria;
    }
  }

  String _getTextoTipoArchivo(String tipo) {
    switch (tipo) {
      case 'imagen':
        return 'Imagen';
      case 'video':
        return 'Video';
      case 'pdf':
        return 'PDF';
      case 'documento':
        return 'Documento';
      case 'audio':
        return 'Audio';
      default:
        return tipo;
    }
  }
}

// Listas de filtros (deben estar definidas como propiedades de la clase)
final List<String> _categoriasFiltro = [
  'todas',
  'ejercicios',
  'nutricion',
  'rutinas',
  'tecnica',
  'salud',
  'general'
];

final List<String> _tiposArchivoFiltro = [
  'todos',
  'imagen',
  'video',
  'pdf',
  'documento',
  'audio',
  'enlace'
];
