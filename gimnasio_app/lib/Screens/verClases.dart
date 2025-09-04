import 'package:flutter/material.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';

class VerClasesScreen extends StatefulWidget {
  final RepositorioAPI api;
  const VerClasesScreen({Key? key, required this.api}) : super(key: key);

  @override
  State<VerClasesScreen> createState() => _VerClasesScreenState();
}

class _VerClasesScreenState extends State<VerClasesScreen> {
  List<dynamic> _clases = [];
  bool _cargando = true;
  String _error = '';
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  String _dificultadSeleccionada = 'Todas';

  final List<String> _dificultades = ['Todas', 'Baja', 'Media', 'Alta'];

  @override
  void initState() {
    super.initState();
    _cargarClases();
  }

  Future<void> _cargarClases() async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.obtenerClases();
      setState(() {
        _clases = data;
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
      // Filtrado local si el backend no tiene endpoint específico
      final todas = await widget.api.obtenerClases();
      final filtradas = todas
          .where((c) =>
              c['nombre'] != null &&
              c['nombre']
                  .toString()
                  .toLowerCase()
                  .contains(nombre.toLowerCase()))
          .toList();
      setState(() {
        _clases = filtradas;
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

  Future<void> _buscarPorInstructor(String instructor) async {
    setState(() => _cargando = true);
    try {
      final data = await widget.api.buscarClasesPorInstructor(instructor);
      setState(() {
        _clases = data;
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

  Future<void> _buscarPorDificultad(String dificultad) async {
    setState(() => _cargando = true);
    try {
      if (dificultad == 'Todas') {
        await _cargarClases();
      } else {
        final data = await widget.api.buscarClasesPorDificultad(dificultad);
        setState(() {
          _clases = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clases disponibles'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarClases,
          ),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Text(_error, style: TextStyle(color: Colors.red)),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _busquedaController,
                            decoration: InputDecoration(
                              labelText: 'Buscar por nombre',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.send),
                                onPressed: () {
                                  if (_busquedaController.text.isNotEmpty) {
                                    _buscarPorNombre(_busquedaController.text);
                                  }
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _instructorController,
                            decoration: InputDecoration(
                              labelText: 'Buscar por instructor',
                              prefixIcon: Icon(Icons.person),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.send),
                                onPressed: () {
                                  if (_instructorController.text.isNotEmpty) {
                                    _buscarPorInstructor(
                                        _instructorController.text);
                                  }
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _dificultadSeleccionada,
                            items: _dificultades.map((String dificultad) {
                              return DropdownMenuItem<String>(
                                value: dificultad,
                                child: Text(dificultad),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _dificultadSeleccionada = value!;
                                _buscarPorDificultad(_dificultadSeleccionada);
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Filtrar por dificultad',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _clases.isEmpty
                          ? Center(child: Text('No se encontraron clases'))
                          : ListView.builder(
                              itemCount: _clases.length,
                              itemBuilder: (context, index) {
                                final clase = _clases[index];
                                return Card(
                                  margin: EdgeInsets.all(8),
                                  child: ListTile(
                                    title:
                                        Text(clase['nombre'] ?? 'Sin nombre'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Instructor: ${clase['instructor'] ?? 'Desconocido'}'),
                                        Text(
                                            'Dificultad: ${clase['dificultad'] ?? 'Sin nivel'}'),
                                        Text(
                                            'Horario: ${clase['horario'] ?? 'Sin horario'}'),
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
}
