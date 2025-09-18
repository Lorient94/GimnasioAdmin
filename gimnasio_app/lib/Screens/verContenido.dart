import 'package:flutter/material.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VerContenidoScreen extends StatefulWidget {
  final RepositorioAPI api;
  const VerContenidoScreen({Key? key, required this.api}) : super(key: key);

  @override
  State<VerContenidoScreen> createState() => _VerContenidoScreenState();
}

class _VerContenidoScreenState extends State<VerContenidoScreen> {
  List<dynamic> _contenidos = [];
  bool _cargando = true;
  String _error = '';
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  final List<String> _categorias = [
    'Todas',
    'video',
    'foto',
    'texto',
    'enlace'
  ];
  String _categoriaSeleccionada = 'Todas';

  @override
  void initState() {
    super.initState();
    _cargarContenidos();
  }

  Future<void> _cargarContenidos() async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.obtenerContenidos();
      setState(() {
        _contenidos = data;
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

  Future<void> _buscarPorNombre(String nombre) async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.buscarContenidosPorPalabra(nombre);
      setState(() {
        _contenidos = data;
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

  Future<void> _filtrarPorCategoria(String categoria) async {
    setState(() => _cargando = true);
    try {
      if (categoria == 'Todas') {
        await _cargarContenidos();
      } else {
        final data = await widget.api.obtenerContenidos(categoria: categoria);
        setState(() {
          _contenidos = data;
          _cargando = false;
          _error = '';
        });
      }
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
      final data = await widget.api.buscarContenidosPorFecha(fecha);
      setState(() {
        _contenidos = data;
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

  Future<void> _descargarContenido(int contenidoId, String titulo) async {
    setState(() => _cargando = true);
    try {
      final bytes = await widget.api.descargarContenido(contenidoId);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$titulo.bin');
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Descargado en ${file.path}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al descargar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarDialogoFecha() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    ).then((fechaSeleccionada) {
      if (fechaSeleccionada != null) {
        _fechaController.text =
            DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
        _buscarPorFecha(_fechaController.text);
      }
    });
  }

  void _mostrarDetallesContenido(dynamic contenido) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            contenido['titulo'] ?? 'Sin título',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Categoría', contenido['categoria']),
                _buildInfoRow(
                    'Fecha', _formatearFecha(contenido['fecha_creacion'])),
                _buildInfoRow('Estado',
                    contenido['activo'] == true ? 'Activo' : 'Inactivo'),
                SizedBox(height: 16),
                Text(
                  'Descripción:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  contenido['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                if (contenido['url'] != null)
                  _buildInfoRow('URL', contenido['url']),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            if (contenido['url'] != null)
              ElevatedButton(
                onPressed: () => _descargarContenido(
                  contenido['id'],
                  contenido['titulo'] ?? 'contenido',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Descargar'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: TextStyle(color: Colors.grey[700]),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
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

  IconData _obtenerIconoCategoria(String categoria) {
    switch (categoria) {
      case 'video':
        return Icons.videocam_outlined;
      case 'foto':
        return Icons.photo_outlined;
      case 'texto':
        return Icons.article_outlined;
      case 'enlace':
        return Icons.link_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _obtenerColorCategoria(String categoria) {
    switch (categoria) {
      case 'video':
        return Colors.red;
      case 'foto':
        return Colors.blue;
      case 'texto':
        return Colors.green;
      case 'enlace':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contenidos Disponibles',
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
            onPressed: _cargarContenidos,
            tooltip: 'Recargar contenidos',
          ),
        ],
      ),
      body: Container(
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
                        Icon(Icons.error_outline, size: 50, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          _error,
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _cargarContenidos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Filtros de búsqueda
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            // Selector de categoría
                            DropdownButtonFormField<String>(
                              value: _categoriaSeleccionada,
                              items: _categorias.map((String categoria) {
                                return DropdownMenuItem<String>(
                                  value: categoria,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _obtenerIconoCategoria(categoria),
                                        color:
                                            _obtenerColorCategoria(categoria),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        categoria,
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? nuevaCategoria) {
                                setState(() {
                                  _categoriaSeleccionada = nuevaCategoria!;
                                });
                                _filtrarPorCategoria(nuevaCategoria!);
                              },
                              decoration: InputDecoration(
                                labelText: 'Filtrar por categoría',
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
                            SizedBox(height: 12),

                            // Búsqueda por nombre
                            TextField(
                              controller: _busquedaController,
                              decoration: InputDecoration(
                                labelText: 'Buscar por nombre',
                                labelStyle: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.grey[600]),
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
                                  _buscarPorNombre(value);
                                }
                              },
                            ),
                            SizedBox(height: 12),

                            // Búsqueda por fecha
                            ElevatedButton(
                              onPressed: _mostrarDialogoFecha,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
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
                          children: [
                            Icon(Icons.collections_bookmark,
                                size: 20,
                                color: Theme.of(context).primaryColor),
                            SizedBox(width: 8),
                            Text(
                              '${_contenidos.length} contenido(s) encontrado(s)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                            Spacer(),
                            if (_categoriaSeleccionada != 'Todas')
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _obtenerColorCategoria(
                                          _categoriaSeleccionada)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _obtenerColorCategoria(
                                            _categoriaSeleccionada)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _categoriaSeleccionada,
                                  style: TextStyle(
                                    color: _obtenerColorCategoria(
                                        _categoriaSeleccionada),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Lista de contenidos
                      Expanded(
                        child: _contenidos.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 60, color: Colors.grey[400]),
                                    SizedBox(height: 16),
                                    Text(
                                      'No se encontraron contenidos',
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
                                itemCount: _contenidos.length,
                                itemBuilder: (context, index) {
                                  final contenido = _contenidos[index];
                                  final categoria =
                                      contenido['categoria'] ?? 'desconocido';
                                  final colorCategoria =
                                      _obtenerColorCategoria(categoria);

                                  return Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _mostrarDetallesContenido(
                                            contenido),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: colorCategoria
                                                          .withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      _obtenerIconoCategoria(
                                                          categoria),
                                                      color: colorCategoria,
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
                                                          contenido['titulo'] ??
                                                              'Sin título',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors
                                                                .grey[800],
                                                          ),
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          contenido[
                                                                  'descripcion'] ??
                                                              'Sin descripción',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
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
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: colorCategoria
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      categoria.toUpperCase(),
                                                      style: TextStyle(
                                                        color: colorCategoria,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Icon(Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.grey[600]),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    _formatearFecha(contenido[
                                                        'fecha_creacion']),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  if (contenido['url'] != null)
                                                    IconButton(
                                                      icon: Icon(Icons.download,
                                                          color: Theme.of(
                                                                  context)
                                                              .primaryColor),
                                                      onPressed: () =>
                                                          _descargarContenido(
                                                        contenido['id'],
                                                        contenido['titulo'] ??
                                                            'contenido',
                                                      ),
                                                      tooltip:
                                                          'Descargar contenido',
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
    );
  }
}
