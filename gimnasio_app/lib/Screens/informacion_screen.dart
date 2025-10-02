// screens/informacion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/informacion_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class InformacionScreen extends StatefulWidget {
  const InformacionScreen({Key? key}) : super(key: key);

  @override
  State<InformacionScreen> createState() => _InformacionScreenState();
}

class _InformacionScreenState extends State<InformacionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroTipoSeleccionado = 'todos'; // Filtro actual
  final List<String> _tiposFiltro = [
    'todos',
    'noticia',
    'anuncio',
    'evento',
    'promocion',
    'recordatorio',
    'alerta',
    'general'
  ];

  @override
  void initState() {
    super.initState();
    context.read<InformacionCubit>().cargarInformaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _mostrarDialogoCrearInformacion() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _CrearInformacionWidget(
            onGuardar: (datosInformacion) async {
              final cubit = context.read<InformacionCubit>();
              await cubit.crearInformacion(datosInformacion);
              if (mounted) Navigator.of(context).pop();
            },
            onCancelar: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _editarInformacion(Map<String, dynamic> informacion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _EditarInformacionWidget(
            informacion: informacion,
            onGuardar: (datosActualizados) async {
              final cubit = context.read<InformacionCubit>();
              await cubit.actualizarInformacion(
                informacion['id'] as int,
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
                  'Filtrar por tipo:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Botones de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tiposFiltro.map((tipo) {
                return _buildBotonFiltro(tipo);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFiltro(String tipo) {
    final bool seleccionado = _filtroTipoSeleccionado == tipo;
    final String texto = _getTextoFiltro(tipo);
    final IconData icono = _getIconoFiltro(tipo);
    final Color color = _getColorFiltro(tipo);

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
            _filtroTipoSeleccionado = selected ? tipo : 'todos';
          });
          _aplicarFiltroTipo(_filtroTipoSeleccionado);
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

  String _getTextoFiltro(String tipo) {
    switch (tipo) {
      case 'todos':
        return 'Todos';
      case 'noticia':
        return 'Noticias';
      case 'anuncio':
        return 'Anuncios';
      case 'evento':
        return 'Eventos';
      case 'promocion':
        return 'Promociones';
      case 'recordatorio':
        return 'Recordatorios';
      case 'alerta':
        return 'Alertas';
      case 'general':
        return 'General';
      default:
        return tipo;
    }
  }

  IconData _getIconoFiltro(String tipo) {
    switch (tipo) {
      case 'todos':
        return Icons.all_inclusive;
      case 'noticia':
        return Icons.article;
      case 'anuncio':
        return Icons.campaign;
      case 'evento':
        return Icons.event;
      case 'promocion':
        return Icons.local_offer;
      case 'recordatorio':
        return Icons.notifications;
      case 'alerta':
        return Icons.warning;
      case 'general':
        return Icons.info;
      default:
        return Icons.category;
    }
  }

  Color _getColorFiltro(String tipo) {
    switch (tipo) {
      case 'todos':
        return Colors.blue;
      case 'noticia':
        return Colors.green;
      case 'anuncio':
        return Colors.orange;
      case 'evento':
        return Colors.purple;
      case 'promocion':
        return Colors.red;
      case 'recordatorio':
        return Colors.amber;
      case 'alerta':
        return Colors.deepOrange;
      case 'general':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  void _aplicarFiltroTipo(String tipo) {
    final cubit = context.read<InformacionCubit>();

    if (tipo == 'todos') {
      // Si es "todos", quitar filtro de tipo
      cubit.filtrarLocalmente(_searchController.text);
    } else {
      // Aplicar filtro por tipo
      cubit.filtrarPorTipo(tipo, _searchController.text);
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroTipoSeleccionado = 'todos';
      _searchController.clear();
    });
    context.read<InformacionCubit>().cargarInformaciones();
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

    if (_filtroTipoSeleccionado != 'todos') {
      filtros.add('Tipo: ${_getTextoFiltro(_filtroTipoSeleccionado)}');
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
        title: const Text('Gestión de Información'),
        backgroundColor: Colors.blue[700],
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
            onPressed: () =>
                context.read<InformacionCubit>().cargarInformaciones(),
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
                hintText: 'Buscar por título, contenido o tipo...',
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _aplicarFiltroTipo(_filtroTipoSeleccionado);
                        },
                      )
                    : null,
              ),
              onChanged: (value) => _aplicarFiltroTipo(_filtroTipoSeleccionado),
            ),
          ),

          // Panel de filtros por tipo
          _buildPanelFiltros(),

          // Indicador de filtro activo
          if (_filtroTipoSeleccionado != 'todos' ||
              _searchController.text.isNotEmpty)
            _buildIndicadorFiltrosActivos(),

          // Lista de informaciones
          Expanded(
            child: BlocBuilder<InformacionCubit, InformacionState>(
              builder: (context, state) {
                if (state is InformacionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is InformacionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<InformacionCubit>()
                              .cargarInformaciones(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is InformacionLoaded) {
                  final informaciones = state.filtradas;

                  if (informaciones.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay informaciones disponibles',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para crear una nueva',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: informaciones.length,
                    itemBuilder: (context, index) {
                      final informacion = informaciones[index];
                      return _InformacionCard(
                        informacion: informacion,
                        onActivar: () => _activarInformacion(informacion),
                        onDesactivar: () => _desactivarInformacion(informacion),
                        onEliminar: () => _eliminarInformacion(informacion),
                        onEditar: () => _editarInformacion(informacion),
                        onVerDetalles: () =>
                            _verDetallesInformacion(informacion),
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
        onPressed: _mostrarDialogoCrearInformacion,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ========== MÉTODOS DE GESTIÓN ==========

  Future<void> _activarInformacion(Map<String, dynamic> informacion) async {
    final confirmado = await _mostrarDialogoConfirmacion(
      'Activar Información',
      '¿Estás seguro de activar esta información?',
    );

    if (confirmado) {
      final cubit = context.read<InformacionCubit>();
      try {
        await cubit.activarInformacion(informacion['id'] as int);
        _mostrarMensaje('Información activada exitosamente');
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  Future<void> _desactivarInformacion(Map<String, dynamic> informacion) async {
    final confirmado = await _mostrarDialogoConfirmacion(
      'Desactivar Información',
      '¿Estás seguro de desactivar esta información?',
    );

    if (confirmado) {
      final cubit = context.read<InformacionCubit>();
      try {
        await cubit.desactivarInformacion(informacion['id'] as int);
        _mostrarMensaje('Información desactivada exitosamente');
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  Future<void> _eliminarInformacion(Map<String, dynamic> informacion) async {
    final confirmado = await _mostrarDialogoConfirmacion(
      'Eliminar Información',
      '¿Estás seguro de eliminar permanentemente esta información?',
    );

    if (confirmado) {
      final cubit = context.read<InformacionCubit>();
      try {
        await cubit.eliminarInformacion(informacion['id'] as int);
        _mostrarMensaje('Información eliminada exitosamente');
      } catch (e) {
        _mostrarMensaje('Error: $e', esError: true);
      }
    }
  }

  void _verDetallesInformacion(Map<String, dynamic> informacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Información'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalleItem('ID', informacion['id']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Título', informacion['titulo']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Tipo', informacion['tipo']?.toString() ?? 'N/A'),
              _buildDetalleItem(
                  'Contenido', informacion['contenido']?.toString() ?? 'N/A'),
              _buildDetalleItem('Estado',
                  informacion['activa'] == true ? 'Activa' : 'Inactiva'),
              _buildDetalleItem('Fecha Creación',
                  informacion['fecha_creacion']?.toString() ?? 'N/A'),
              if (informacion['fecha_expiracion'] != null)
                _buildDetalleItem('Fecha Expiración',
                    informacion['fecha_expiracion']?.toString() ?? 'N/A'),
              if (informacion['destinatario'] != null)
                _buildDetalleItem('Destinatario',
                    informacion['destinatario']?.toString() ?? 'N/A'),
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

// Widget para tarjeta de información
class _InformacionCard extends StatelessWidget {
  final Map<String, dynamic> informacion;
  final VoidCallback? onActivar;
  final VoidCallback? onDesactivar;
  final VoidCallback? onEliminar;
  final VoidCallback? onEditar;
  final VoidCallback? onVerDetalles;

  const _InformacionCard({
    Key? key,
    required this.informacion,
    this.onActivar,
    this.onDesactivar,
    this.onEliminar,
    this.onEditar,
    this.onVerDetalles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titulo = informacion['titulo']?.toString() ?? 'Sin título';
    final tipo = informacion['tipo']?.toString() ?? 'Sin tipo';
    final activa = informacion['activa'] == true;
    final contenido = informacion['contenido']?.toString() ?? '';
    final fechaCreacion = informacion['fecha_creacion']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activa ? Colors.green : Colors.grey,
          child: Icon(
            _getIconPorTipo(tipo),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: activa ? null : TextDecoration.lineThrough,
            )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$tipo • ${activa ? 'Activa' : 'Inactiva'}'),
            if (contenido.isNotEmpty)
              Text(
                contenido.length > 50
                    ? '${contenido.substring(0, 50)}...'
                    : contenido,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (fechaCreacion.isNotEmpty)
              Text(
                'Creado: $fechaCreacion',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                activa ? 'ACTIVA' : 'INACTIVA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: activa ? Colors.green : Colors.grey,
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuSelection(value, context),
              itemBuilder: (context) => _buildMenuItems(activa),
            ),
          ],
        ),
        onTap: onVerDetalles,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(bool activa) {
    final items = <PopupMenuEntry<String>>[];

    items.add(
        const PopupMenuItem(value: 'detalles', child: Text('Ver Detalles')));
    items.add(const PopupMenuItem(value: 'editar', child: Text('Editar')));

    if (activa) {
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

  IconData _getIconPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'noticia':
        return Icons.article;
      case 'anuncio':
        return Icons.campaign;
      case 'evento':
        return Icons.event;
      case 'promocion':
        return Icons.local_offer;
      case 'recordatorio':
        return Icons.notifications;
      case 'alerta':
        return Icons.warning;
      case 'general':
        return Icons.info;
      default:
        return Icons.category;
    }
  }
}

// Widget para Crear Información (interno)
class _CrearInformacionWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onGuardar;
  final VoidCallback onCancelar;

  const _CrearInformacionWidget({
    Key? key,
    required this.onGuardar,
    required this.onCancelar,
  }) : super(key: key);

  @override
  State<_CrearInformacionWidget> createState() =>
      __CrearInformacionWidgetState();
}

class __CrearInformacionWidgetState extends State<_CrearInformacionWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  final TextEditingController _destinatarioController = TextEditingController();

  String _tipoSeleccionado = 'noticia';
  bool _activa = true;
  DateTime? _fechaExpiracion;

  final List<String> _tipos = [
    'noticia',
    'anuncio',
    'evento',
    'promocion',
    'recordatorio',
    'alerta',
    'general'
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _destinatarioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaExpiracion() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaExpiracion = fechaSeleccionada;
      });
    }
  }

  void _limpiarFechaExpiracion() {
    setState(() {
      _fechaExpiracion = null;
    });
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final datosInformacion = {
        'titulo': _tituloController.text.trim(),
        'contenido': _contenidoController.text.trim(),
        'tipo': _tipoSeleccionado,
        'activa': _activa,
        if (_destinatarioController.text.isNotEmpty)
          'destinatario': _destinatarioController.text.trim(),
        if (_fechaExpiracion != null)
          'fecha_expiracion': _fechaExpiracion!.toIso8601String(),
      };

      widget.onGuardar(datosInformacion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Información'),
        backgroundColor: Colors.blue[700],
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
                  hintText: 'Ingrese el título de la información',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                items: _tipos.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(
                      _getTextoFiltro(tipo),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Contenido
              TextFormField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  labelText: 'Contenido *',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese el contenido de la información',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El contenido es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Destinatario (opcional)
              TextFormField(
                controller: _destinatarioController,
                decoration: const InputDecoration(
                  labelText: 'Destinatario (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'DNI o grupo destinatario',
                ),
              ),
              const SizedBox(height: 16),

              // Fecha de expiración
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Expiración (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _fechaExpiracion != null
                            ? '${_fechaExpiracion!.day}/${_fechaExpiracion!.month}/${_fechaExpiracion!.year}'
                            : 'No establecida',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _seleccionarFechaExpiracion,
                    tooltip: 'Seleccionar fecha',
                  ),
                  if (_fechaExpiracion != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: _limpiarFechaExpiracion,
                      tooltip: 'Limpiar fecha',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Estado activo/inactivo
              SwitchListTile(
                title: const Text('Información Activa'),
                subtitle: const Text(
                    'La información será visible para los destinatarios'),
                value: _activa,
                onChanged: (value) {
                  setState(() {
                    _activa = value;
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
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar Información'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTextoFiltro(String tipo) {
    switch (tipo) {
      case 'noticia':
        return 'Noticia';
      case 'anuncio':
        return 'Anuncio';
      case 'evento':
        return 'Evento';
      case 'promocion':
        return 'Promoción';
      case 'recordatorio':
        return 'Recordatorio';
      case 'alerta':
        return 'Alerta';
      case 'general':
        return 'General';
      default:
        return tipo;
    }
  }
}

// Widget para Editar Información (interno)
class _EditarInformacionWidget extends StatefulWidget {
  final Map<String, dynamic> informacion;
  final Function(Map<String, dynamic>) onGuardar;
  final VoidCallback onCancelar;

  const _EditarInformacionWidget({
    Key? key,
    required this.informacion,
    required this.onGuardar,
    required this.onCancelar,
  }) : super(key: key);

  @override
  State<_EditarInformacionWidget> createState() =>
      __EditarInformacionWidgetState();
}

class __EditarInformacionWidgetState extends State<_EditarInformacionWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _contenidoController;
  late TextEditingController _destinatarioController;

  late String _tipoSeleccionado;
  late bool _activa;
  DateTime? _fechaExpiracion;

  final List<String> _tipos = [
    'noticia',
    'anuncio',
    'evento',
    'promocion',
    'recordatorio',
    'alerta',
    'general'
  ];

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
        text: widget.informacion['titulo']?.toString() ?? '');
    _contenidoController = TextEditingController(
        text: widget.informacion['contenido']?.toString() ?? '');
    _destinatarioController = TextEditingController(
        text: widget.informacion['destinatario']?.toString() ?? '');

    _tipoSeleccionado = widget.informacion['tipo']?.toString() ?? 'noticia';
    _activa = widget.informacion['activa'] == true;

    if (widget.informacion['fecha_expiracion'] != null) {
      try {
        _fechaExpiracion =
            DateTime.parse(widget.informacion['fecha_expiracion']);
      } catch (e) {
        _fechaExpiracion = null;
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _destinatarioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaExpiracion() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate:
          _fechaExpiracion ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaExpiracion = fechaSeleccionada;
      });
    }
  }

  void _limpiarFechaExpiracion() {
    setState(() {
      _fechaExpiracion = null;
    });
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final datosActualizados = {
        'titulo': _tituloController.text.trim(),
        'contenido': _contenidoController.text.trim(),
        'tipo': _tipoSeleccionado,
        'activa': _activa,
        if (_destinatarioController.text.isNotEmpty)
          'destinatario': _destinatarioController.text.trim(),
        if (_fechaExpiracion != null)
          'fecha_expiracion': _fechaExpiracion!.toIso8601String(),
      };

      widget.onGuardar(datosActualizados);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Información'),
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

              // Tipo
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                items: _tipos.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(_getTextoFiltro(tipo)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Contenido
              TextFormField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  labelText: 'Contenido *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El contenido es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Destinatario (opcional)
              TextFormField(
                controller: _destinatarioController,
                decoration: const InputDecoration(
                  labelText: 'Destinatario (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'DNI o grupo destinatario',
                ),
              ),
              const SizedBox(height: 16),

              // Fecha de expiración
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Expiración (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _fechaExpiracion != null
                            ? '${_fechaExpiracion!.day}/${_fechaExpiracion!.month}/${_fechaExpiracion!.year}'
                            : 'No establecida',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _seleccionarFechaExpiracion,
                    tooltip: 'Seleccionar fecha',
                  ),
                  if (_fechaExpiracion != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: _limpiarFechaExpiracion,
                      tooltip: 'Limpiar fecha',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Estado activo/inactivo
              SwitchListTile(
                title: const Text('Información Activa'),
                subtitle: const Text(
                    'La información será visible para los destinatarios'),
                value: _activa,
                onChanged: (value) {
                  setState(() {
                    _activa = value;
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

  String _getTextoFiltro(String tipo) {
    switch (tipo) {
      case 'noticia':
        return 'Noticia';
      case 'anuncio':
        return 'Anuncio';
      case 'evento':
        return 'Evento';
      case 'promocion':
        return 'Promoción';
      case 'recordatorio':
        return 'Recordatorio';
      case 'alerta':
        return 'Alerta';
      case 'general':
        return 'General';
      default:
        return tipo;
    }
  }
}
