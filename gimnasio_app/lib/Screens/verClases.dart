import 'package:flutter/material.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';
import 'package:gimnasio_app/services/auth_service.dart';

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
  String? _clienteDni;

  final List<String> _dificultades = ['Todas', 'Baja', 'Media', 'Alta'];

  @override
  void initState() {
    super.initState();
    _obtenerUsuarioYcargarClases();
  }

  Future<void> _obtenerUsuarioYcargarClases() async {
    setState(() => _cargando = true);
    try {
      final userData = await AuthService.getUserData();
      _clienteDni = userData?['dni'];
      await _cargarClases();
    } catch (e) {
      setState(() {
        _error = 'Error obteniendo usuario: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarClases() async {
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

  Future<void> _inscribirseAClase(int claseId, String nombreClase) async {
    if (_clienteDni == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes iniciar sesión para inscribirte'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final datos = {
        'cliente_dni': _clienteDni,
        'clase_id': claseId,
        'fecha_inscripcion': DateTime.now().toIso8601String(),
      };

      final response = await widget.api.crearInscripcion(datos);

      if (response != null && response['id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Inscrito a $nombreClase correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ No se pudo completar la inscripción'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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

  void _mostrarDialogoInscripcion(int claseId, String nombreClase) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirmar inscripción',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          content: Text('¿Deseas inscribirte a la clase "$nombreClase"?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _inscribirseAClase(claseId, nombreClase);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Clases Disponibles',
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
            onPressed: _cargarClases,
            tooltip: 'Actualizar clases',
          ),
          if (_clienteDni != null)
            IconButton(
              icon: Icon(Icons.assignment, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/administrarInscripciones');
              },
              tooltip: 'Ver mis inscripciones',
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
                          onPressed: _cargarClases,
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
                            TextField(
                              controller: _busquedaController,
                              decoration: InputDecoration(
                                labelText: 'Buscar por nombre',
                                labelStyle: TextStyle(color: Colors.grey[600]),
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
                            TextField(
                              controller: _instructorController,
                              decoration: InputDecoration(
                                labelText: 'Buscar por instructor',
                                labelStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon:
                                    Icon(Icons.person, color: Colors.grey[600]),
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
                                  _buscarPorInstructor(value);
                                }
                              },
                            ),
                            SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _dificultadSeleccionada,
                              items: _dificultades.map((String dificultad) {
                                return DropdownMenuItem<String>(
                                  value: dificultad,
                                  child: Text(
                                    dificultad,
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
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
                                labelStyle: TextStyle(color: Colors.grey[600]),
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
                          ],
                        ),
                      ),

                      // Contador de resultados
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.fitness_center,
                                size: 20,
                                color: Theme.of(context).primaryColor),
                            SizedBox(width: 8),
                            Text(
                              '${_clases.length} clase(s) encontrada(s)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de clases
                      Expanded(
                        child: _clases.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.fitness_center,
                                        size: 60, color: Colors.grey[400]),
                                    SizedBox(height: 16),
                                    Text(
                                      'No se encontraron clases',
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
                                itemCount: _clases.length,
                                itemBuilder: (context, index) {
                                  final clase = _clases[index];
                                  return _buildClaseCard(clase);
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildClaseCard(Map<String, dynamic> clase) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clase['nombre'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                            'Instructor', clase['instructor'] ?? 'Desconocido'),
                        _buildInfoRow(
                            'Dificultad', clase['dificultad'] ?? 'Sin nivel'),
                        _buildInfoRow(
                            'Horario', clase['hora'] ?? 'Sin horario'),
                        _buildInfoRow('Días',
                            clase['dias_semana']?.join(', ') ?? 'No definido'),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: _clienteDni != null
                    ? ElevatedButton(
                        onPressed: () {
                          _mostrarDialogoInscripcion(
                            clase['id'],
                            clase['nombre'] ?? 'esta clase',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Inscribirse',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Inicia sesión para inscribirte'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Iniciar sesión para inscribirte',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
