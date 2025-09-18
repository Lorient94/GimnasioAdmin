import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';

class VerInformacionScreen extends StatefulWidget {
  final RepositorioAPI api;
  const VerInformacionScreen({Key? key, required this.api}) : super(key: key);

  @override
  _VerInformacionScreenState createState() => _VerInformacionScreenState();
}

class _VerInformacionScreenState extends State<VerInformacionScreen> {
  List<dynamic> _informaciones = [];
  bool _cargando = true;
  String _error = '';
  String _filtroTipo = 'Todas';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  int? _usuarioId;

  final List<String> _tipos = [
    'Todas',
    'ANUNCIO',
    'ALERTA',
    'NOTICIA',
    'PROMOCION',
    'EVENTO',
    'RECORDATORIO',
    'PERMANENTE',
  ];

  @override
  void initState() {
    super.initState();
    _obtenerUsuarioYcargarInformaciones();
  }

  Future<void> _obtenerUsuarioYcargarInformaciones() async {
    setState(() => _cargando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _usuarioId = prefs.getInt('user_id');
      _cargarInformaciones();
    } catch (e) {
      setState(() {
        _error = 'Error obteniendo usuario: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarInformaciones() async {
    try {
      final data = await widget.api.obtenerInformaciones(
        tipo: _filtroTipo != 'Todas' ? _filtroTipo : null,
      );
      setState(() {
        _informaciones = data;
        _cargando = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarInformacionesCliente() async {
    setState(() => _cargando = true);
    try {
      if (_usuarioId == null) throw Exception('Usuario no logueado');
      final data =
          await widget.api.obtenerInformaciones(destinatarioId: _usuarioId);
      setState(() {
        _informaciones = data;
        _cargando = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarPorTipo(String tipo) async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.obtenerInformaciones(tipo: tipo);
      setState(() {
        _informaciones = data;
        _cargando = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _buscarInformaciones(String palabraClave) async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.buscarInformacionesPorPalabra(palabraClave);
      setState(() {
        _informaciones = data;
        _cargando = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _buscarPorFecha(String fecha) async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.buscarInformacionesPorFecha(fecha);
      setState(() {
        _informaciones = data;
        _cargando = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarAlertasActivas() async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.obtenerInformaciones(tipo: 'ALERTA');
      setState(() {
        _informaciones = data;
        _cargando = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  void _filtrarInformaciones() {
    if (_filtroTipo != 'Todas')
      _cargarPorTipo(_filtroTipo);
    else
      _cargarInformaciones();
  }

  void _mostrarDialogoFecha() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((fechaSeleccionada) {
      if (fechaSeleccionada != null) {
        _fechaController.text =
            DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
        _buscarPorFecha(_fechaController.text);
      }
    });
  }

  IconData _obtenerIconoTipo(String tipo) {
    switch (tipo) {
      case 'ANUNCIO':
        return Icons.announcement_outlined;
      case 'ALERTA':
        return Icons.warning_amber_outlined;
      case 'NOTICIA':
        return Icons.newspaper_outlined;
      case 'PROMOCION':
        return Icons.local_offer_outlined;
      case 'EVENTO':
        return Icons.event_outlined;
      case 'RECORDATORIO':
        return Icons.notifications_none_outlined;
      case 'PERMANENTE':
        return Icons.all_inclusive_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _obtenerColorTipo(String tipo) {
    switch (tipo) {
      case 'ANUNCIO':
        return Colors.blue;
      case 'ALERTA':
        return Colors.red;
      case 'NOTICIA':
        return Colors.orange;
      case 'PROMOCION':
        return Colors.green;
      case 'EVENTO':
        return Colors.purple;
      case 'RECORDATORIO':
        return Colors.teal;
      case 'PERMANENTE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'No disponible';
    try {
      final parsedDate = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
    } catch (e) {
      return fecha;
    }
  }

  void _mostrarDetallesInformacion(dynamic informacion) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          informacion['titulo'] ?? 'Sin título',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Tipo', informacion['tipo']),
              _buildInfoRow('Prioridad', informacion['prioridad']?.toString()),
              _buildInfoRow('Fecha publicación',
                  _formatearFecha(informacion['fecha_publicacion'])),
              _buildInfoRow('Fecha expiración',
                  _formatearFecha(informacion['fecha_expiracion'])),
              _buildInfoRow(
                  'Destinatario',
                  informacion['destinatario_id'] != null
                      ? 'Cliente ${informacion['destinatario_id']}'
                      : 'Todos'),
              SizedBox(height: 16),
              Text('Contenido:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[800])),
              SizedBox(height: 8),
              Text(informacion['contenido'] ?? 'Sin contenido',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar', style: TextStyle(color: Colors.grey[600])))
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey[800])),
          Expanded(
              child: Text(value ?? 'No disponible',
                  style: TextStyle(color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alturaPantalla = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sistema de Informaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarInformaciones,
            tooltip: 'Recargar informaciones',
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: _cargando
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : _error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 50, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            _error,
                            style: TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _cargarInformaciones,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            child: Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Filtros de búsqueda
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A73E8),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _filtroTipo,
                                  items: _tipos.map((String tipo) {
                                    return DropdownMenuItem<String>(
                                      value: tipo,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _obtenerIconoTipo(tipo),
                                            color: _obtenerColorTipo(tipo),
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            tipo,
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? nuevoTipo) {
                                    setState(() {
                                      _filtroTipo = nuevoTipo!;
                                    });
                                    _filtrarInformaciones();
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Filtrar por tipo',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  dropdownColor: Colors.white,
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    labelText: 'Buscar por palabra clave',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Icon(Icons.search,
                                        color: Colors.grey[600]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      _buscarInformaciones(value);
                                    }
                                  },
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _cargarInformacionesCliente,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Color(0xFF1A73E8),
                                          minimumSize:
                                              Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person, size: 20),
                                            SizedBox(width: 8),
                                            Text('Mis Informaciones'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _cargarAlertasActivas,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.red,
                                          minimumSize:
                                              Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.warning, size: 20),
                                            SizedBox(width: 8),
                                            Text('Alertas'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _mostrarDialogoFecha,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Color(0xFF1A73E8),
                                    minimumSize: Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today, size: 20),
                                      SizedBox(width: 8),
                                      Text('Buscar por Fecha'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Contador de resultados
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline,
                                    size: 20,
                                    color: Theme.of(context).primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  '${_informaciones.length} información(es) encontrada(s)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                if (_filtroTipo != 'Todas')
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _obtenerColorTipo(_filtroTipo)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _obtenerColorTipo(_filtroTipo)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _filtroTipo,
                                      style: TextStyle(
                                        color: _obtenerColorTipo(_filtroTipo),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Lista de informaciones
                          SizedBox(
                            height: alturaPantalla * 0.55,
                            child: _informaciones.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off,
                                            size: 60, color: Colors.grey[400]),
                                        SizedBox(height: 16),
                                        Text(
                                          'No se encontraron informaciones',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Intenta con otros filtros de búsqueda',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.only(bottom: 16),
                                    itemCount: _informaciones.length,
                                    itemBuilder: (context, index) {
                                      final informacion = _informaciones[index];
                                      final tipo =
                                          informacion['tipo'] ?? 'desconocido';
                                      final colorTipo = _obtenerColorTipo(tipo);

                                      return Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            onTap: () =>
                                                _mostrarDetallesInformacion(
                                                    informacion),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        width: 50,
                                                        height: 50,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: colorTipo
                                                              .withOpacity(0.1),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          _obtenerIconoTipo(
                                                              tipo),
                                                          color: colorTipo,
                                                          size: 24,
                                                        ),
                                                      ),
                                                      SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              informacion[
                                                                      'titulo'] ??
                                                                  'Sin título',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .grey[800],
                                                              ),
                                                            ),
                                                            SizedBox(height: 8),
                                                            Text(
                                                              informacion[
                                                                      'contenido'] ??
                                                                  'Sin contenido',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .grey[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 12),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 12,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: colorTipo
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          tipo.toUpperCase(),
                                                          style: TextStyle(
                                                            color: colorTipo,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Icon(Icons.calendar_today,
                                                          size: 14,
                                                          color:
                                                              Colors.grey[600]),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        _formatearFecha(informacion[
                                                            'fecha_publicacion']),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Spacer(),
                                                      Text(
                                                        informacion['destinatario_id'] !=
                                                                null
                                                            ? '👤 Cliente'
                                                            : '👥 Todos',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
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
}
