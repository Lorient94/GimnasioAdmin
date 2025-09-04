import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';

class VerInformacionScreen extends StatefulWidget {
  final RepositorioAPI api;
  const VerInformacionScreen({
    Key? key,
    required this.api,
  }) : super(key: key);

  @override
  _VerInformacionScreenState createState() => _VerInformacionScreenState();
}

class _VerInformacionScreenState extends State<VerInformacionScreen> {
  List<dynamic> _informaciones = [];
  bool _cargando = true;
  String _error = '';
  String _filtroTipo = 'Todas';
  bool _soloActivas = true;
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
      // Obtener el ID del usuario logueado desde SharedPreferences
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
      if (_usuarioId == null) {
        throw Exception('Usuario no logueado');
      }

      print('Buscando informaciones para usuario ID: $_usuarioId');

      final data = await widget.api.obtenerInformaciones(
        destinatarioId: _usuarioId,
      );

      print('Informaciones encontradas: ${data.length}');

      // DEBUG: Mostrar detalles de cada información
      for (var i = 0; i < data.length; i++) {
        final info = data[i];
        print('Información $i:');
        print('  Título: ${info['titulo']}');
        print('  Tipo: ${info['tipo']}');
        print('  Contenido: ${info['contenido']}');
        print('  Fecha expiración: ${info['fecha_expiracion']}');
        print('  Destinatario ID: ${info['destinatario_id']}');
      }

      setState(() {
        _informaciones = data;
        _cargando = false;
        _error = '';
      });
    } catch (e) {
      print('Error cargando informaciones: $e');
      setState(() {
        _error = 'Error: ${e.toString()}';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarPorTipo(String tipo) async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.obtenerInformaciones(
        tipo: tipo,
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
    if (_filtroTipo != 'Todas') {
      _cargarPorTipo(_filtroTipo);
    } else {
      _cargarInformaciones();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Informaciones'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarInformaciones,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _cargarInformaciones,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por palabra clave...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () {
                                  if (_searchController.text.isNotEmpty) {
                                    _buscarInformaciones(
                                        _searchController.text);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _filtroTipo,
                                  items: _tipos.map((String tipo) {
                                    return DropdownMenuItem<String>(
                                      value: tipo,
                                      child: Text(tipo),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _filtroTipo = value!;
                                      _filtrarInformaciones();
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Filtrar por tipo',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch(
                                value: _soloActivas,
                                onChanged: (value) {
                                  setState(() {
                                    _soloActivas = value;
                                    _cargarInformaciones();
                                  });
                                },
                              ),
                              const Text('Activas'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _cargarInformacionesCliente,
                                  child: const Text('Mis Informaciones'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[400],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _cargarAlertasActivas,
                                  child: const Text('Alertas Activas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[400],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _mostrarDialogoFecha,
                                  child: const Text('Buscar por Fecha'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _informaciones.isEmpty
                          ? const Center(
                              child: Text('No se encontraron informaciones'))
                          : ListView.builder(
                              itemCount: _informaciones.length,
                              itemBuilder: (context, index) {
                                final informacion = _informaciones[index];
                                print(
                                    'Construyendo card para: ${informacion['titulo']}'); // DEBUG

                                return Card(
                                  margin: const EdgeInsets.all(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              informacion['titulo'] ??
                                                  'Sin título',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            Chip(
                                              label: Text(
                                                informacion['tipo'] ??
                                                    'SIN TIPO',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                              backgroundColor: _getColorByTipo(
                                                  informacion['tipo'] ?? ''),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          informacion['contenido'] ??
                                              'Sin contenido',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '👤 Para: ${informacion['destinatario_id'] != null ? 'Cliente ${informacion['destinatario_id']}' : 'Todos'}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '⭐ Prioridad: ${informacion['prioridad']?.toString() ?? '1'}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '📅 Publicado: ${_formatFecha(informacion['fecha_publicacion'] ?? '')}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                        Text(
                                          '⏰ Expira: ${_formatFecha(informacion['fecha_expiracion'] ?? '')}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  String _formatFecha(String? fechaString) {
    if (fechaString == null || fechaString.isEmpty) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaString);
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Color _getColorByTipo(String tipo) {
    switch (tipo) {
      case 'ALERTA':
        return Colors.red;
      case 'PERMANENTE':
        return Colors.grey;
      case 'ANUNCIO':
        return Colors.blue;
      case 'NOTICIA':
        return Colors.orange;
      case 'PROMOCION':
        return Colors.green;
      case 'EVENTO':
        return Colors.purple;
      case 'RECORDATORIO':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
