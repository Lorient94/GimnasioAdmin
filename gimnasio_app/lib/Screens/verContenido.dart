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

  // Lista de categorías predefinidas
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
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al descargar: $e'),
          backgroundColor: Colors.red,
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
    ).then((fechaSeleccionada) {
      if (fechaSeleccionada != null) {
        _fechaController.text =
            DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
        _buscarPorFecha(_fechaController.text);
      }
    });
  }

  // Diálogo para mostrar detalles del contenido
  void _mostrarDetallesContenido(dynamic contenido) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(contenido['titulo'] ?? 'Sin título'),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  contenido['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                if (contenido['url'] != null)
                  _buildInfoRow('URL', contenido['url']),
              ],
            ),
          ),
          actions: [
            if (contenido['url'] != null)
              TextButton(
                onPressed: () => _descargarContenido(
                  contenido['id'],
                  contenido['titulo'] ?? 'contenido',
                ),
                child: Text('DESCARGAR'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('CERRAR'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value ?? 'No disponible',
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
        return Icons.videocam;
      case 'foto':
        return Icons.photo;
      case 'texto':
        return Icons.article;
      case 'enlace':
        return Icons.link;
      default:
        return Icons.category;
    }
  }

  Color _obtenerColorCategoria(String categoria) {
    switch (categoria) {
      case 'video':
        return Colors.redAccent;
      case 'foto':
        return Colors.blueAccent;
      case 'texto':
        return Colors.greenAccent;
      case 'enlace':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 Contenidos Disponibles'),
        backgroundColor: Colors.deepPurple[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarContenidos,
            tooltip: 'Recargar contenidos',
          ),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      SizedBox(height: 16),
                      Text(
                        _error,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _cargarContenidos,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filtros de búsqueda
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // Selector de categoría
                          Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              child: DropdownButton<String>(
                                value: _categoriaSeleccionada,
                                isExpanded: true,
                                underline: SizedBox(),
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
                                        Text(categoria),
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
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Búsqueda por nombre
                          TextField(
                            controller: _busquedaController,
                            decoration: InputDecoration(
                              labelText: '🔍 Buscar por nombre',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.search),
                                onPressed: () {
                                  if (_busquedaController.text.isNotEmpty) {
                                    _buscarPorNombre(_busquedaController.text);
                                  }
                                },
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _buscarPorNombre(value);
                              }
                            },
                          ),
                          SizedBox(height: 12),

                          // Búsqueda por fecha
                          ElevatedButton.icon(
                            onPressed: _mostrarDialogoFecha,
                            icon: Icon(Icons.calendar_today),
                            label: Text('📅 Buscar por Fecha'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contador de resultados
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '📊 ${_contenidos.length} contenido(s) encontrado(s)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_categoriaSeleccionada != 'Todas')
                            Chip(
                              label: Text(_categoriaSeleccionada),
                              backgroundColor:
                                  _obtenerColorCategoria(_categoriaSeleccionada)
                                      .withOpacity(0.2),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),

                    // Lista de contenidos
                    Expanded(
                      child: _contenidos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 60, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No se encontraron contenidos',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Intenta con otros filtros de búsqueda',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _contenidos.length,
                              itemBuilder: (context, index) {
                                final contenido = _contenidos[index];
                                final categoria =
                                    contenido['categoria'] ?? 'desconocido';

                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Icon(
                                      _obtenerIconoCategoria(categoria),
                                      color: _obtenerColorCategoria(categoria),
                                      size: 28,
                                    ),
                                    title: Text(
                                      contenido['titulo'] ?? 'Sin título',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          contenido['descripcion'] ??
                                              'Sin descripción',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(
                                                categoria.toUpperCase(),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white),
                                              ),
                                              backgroundColor:
                                                  _obtenerColorCategoria(
                                                      categoria),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _formatearFecha(
                                                  contenido['fecha_creacion']),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: contenido['url'] != null
                                        ? IconButton(
                                            icon: Icon(Icons.download,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _descargarContenido(
                                              contenido['id'],
                                              contenido['titulo'] ??
                                                  'contenido',
                                            ),
                                            tooltip: 'Descargar contenido',
                                          )
                                        : null,
                                    onTap: () =>
                                        _mostrarDetallesContenido(contenido),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
