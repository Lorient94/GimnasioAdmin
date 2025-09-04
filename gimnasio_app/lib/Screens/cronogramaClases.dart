import 'package:flutter/material.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class CronogramaClasesScreen extends StatefulWidget {
  final RepositorioAPI api;
  const CronogramaClasesScreen({Key? key, required this.api}) : super(key: key);

  @override
  State<CronogramaClasesScreen> createState() => _CronogramaClasesScreenState();
}

class _CronogramaClasesScreenState extends State<CronogramaClasesScreen> {
  List<dynamic> _inscripciones = [];
  List<dynamic> _clases = [];
  bool _cargando = true;
  String _error = '';
  String? _clienteDni;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioYDatos();
  }

  Future<void> _cargarUsuarioYDatos() async {
    setState(() => _cargando = true);
    try {
      final userData = await AuthService.getUserData();
      _clienteDni = userData?['dni'];
      if (_clienteDni == null) {
        setState(() {
          _error = 'No se encontró el usuario autenticado';
          _cargando = false;
        });
        return;
      }
      await _cargarCronograma();
    } catch (e) {
      setState(() {
        _error = 'Error al obtener usuario: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarCronograma() async {
    setState(() => _cargando = true);
    try {
      final inscripciones =
          await widget.api.obtenerInscripciones(clienteDni: _clienteDni);
      final clases = await widget.api.obtenerClases();
      setState(() {
        _inscripciones = inscripciones;
        _clases = clases;
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

  List<Map<String, dynamic>> _getEventosPorDia(DateTime dia) {
    final formatoFecha = DateFormat('yyyy-MM-dd');
    return _inscripciones.where((insc) {
      final clase = _clases.firstWhere(
        (c) => c['id'] == insc['clase_id'],
        orElse: () => null,
      );
      if (clase == null || clase['horario'] == null) return false;
      // Se espera que 'horario' sea tipo 'yyyy-MM-dd HH:mm'
      final fechaClase = DateFormat('yyyy-MM-dd HH:mm').parse(clase['horario']);
      return formatoFecha.format(fechaClase) == formatoFecha.format(dia);
    }).map((insc) {
      final clase = _clases.firstWhere((c) => c['id'] == insc['clase_id'],
          orElse: () => null);
      return {
        'nombre': clase?['nombre'] ?? '',
        'horario': clase?['horario'] ?? '',
        'instructor': clase?['instructor'] ?? '',
        'dificultad': clase?['dificultad'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final dias = List.generate(7, (i) => hoy.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Cronograma de Clases'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarUsuarioYDatos,
          ),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: dias.length,
                  itemBuilder: (context, index) {
                    final dia = dias[index];
                    final eventos = _getEventosPorDia(dia);
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text(
                            DateFormat('EEEE dd/MM/yyyy', 'es_ES').format(dia)),
                        children: eventos.isEmpty
                            ? [ListTile(title: Text('Sin clases este día'))]
                            : eventos.map((evento) {
                                return ListTile(
                                  title: Text(evento['nombre']),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Horario: ${evento['horario']}'),
                                      Text(
                                          'Instructor: ${evento['instructor']}'),
                                      Text(
                                          'Dificultad: ${evento['dificultad']}'),
                                    ],
                                  ),
                                );
                              }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
