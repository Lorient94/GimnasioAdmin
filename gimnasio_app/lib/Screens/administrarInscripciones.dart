import 'package:flutter/material.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';
import '../services/auth_service.dart';

class AdministrarInscripcionesScreen extends StatefulWidget {
  final RepositorioAPI api;

  const AdministrarInscripcionesScreen({Key? key, required this.api})
      : super(key: key);

  @override
  State<AdministrarInscripcionesScreen> createState() =>
      _AdministrarInscripcionesScreenState();
}

class _AdministrarInscripcionesScreenState
    extends State<AdministrarInscripcionesScreen> {
  List<dynamic> _inscripciones = [];
  List<dynamic> _clasesDisponibles = [];
  bool _cargando = true;
  String _error = '';
  int? _claseSeleccionada;
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
      await _cargarDatos();
    } catch (e) {
      setState(() {
        _error = 'Error al obtener usuario: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final [inscripciones, clases] = await Future.wait([
        widget.api.obtenerInscripciones(clienteDni: _clienteDni),
        widget.api.obtenerClases(),
      ]);

      setState(() {
        _inscripciones = inscripciones;
        _clasesDisponibles = clases;
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

  Future<void> _inscribirseAClase() async {
    if (_claseSeleccionada == null || _clienteDni == null) return;

    setState(() => _cargando = true);
    try {
      final datos = {
        'cliente_dni': _clienteDni,
        'clase_id': _claseSeleccionada,
        'fecha_inscripcion': DateTime.now().toIso8601String(),
      };

      final response = await widget.api.crearInscripcion(datos);

      if (response != null && response['id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Inscripción realizada correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        await _cargarDatos();
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

  Future<void> _mostrarDialogoCancelacion(
      int inscripcionId, String nombreClase) async {
    final motivoController = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirmar cancelación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  '¿Estás seguro de que quieres cancelar tu inscripción a "$nombreClase"?'),
              SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo de cancelación (opcional)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                maxLines: 3,
              ),
            ],
          ),
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
                Navigator.pop(context, motivoController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Confirmar cancelación'),
            ),
          ],
        );
      },
    );

    if (motivo != null) {
      await _cancelarInscripcion(inscripcionId, motivo);
    }
  }

  Future<void> _cancelarInscripcion(int inscripcionId, String motivo) async {
    setState(() => _cargando = true);
    try {
      final response =
          await widget.api.cancelarInscripcion(inscripcionId, motivo);

      if (response != null && response['estado'] == 'cancelado') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Inscripción cancelada exitosamente'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        await _cargarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ No se pudo cancelar la inscripción'),
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
          content: Text('Error al cancelar: $e'),
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

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'No especificada';
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }

  String _traducirEstado(String? estado) {
    switch (estado) {
      case 'activo':
        return 'Activa';
      case 'cancelado':
        return 'Cancelada';
      case 'completado':
        return 'Completada';
      default:
        return estado ?? 'Desconocido';
    }
  }

  String _obtenerNombreClase(int claseId) {
    try {
      final clase = _clasesDisponibles.firstWhere(
        (clase) => clase['id'] == claseId,
        orElse: () => {'nombre': 'Clase $claseId'},
      );
      return clase['nombre'] ?? 'Clase $claseId';
    } catch (e) {
      return 'Clase $claseId';
    }
  }

  @override
  Widget build(BuildContext context) {
    final inscripcionesActivas = _inscripciones.where((insc) {
      final estado = insc['estado']?.toString() ?? '';
      return estado == 'activo';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Inscripciones',
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
            onPressed: _cargarUsuarioYDatos,
            tooltip: 'Actualizar',
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
                          onPressed: _cargarUsuarioYDatos,
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
                      // Sección para inscribirse a nuevas clases
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inscribirse a una nueva clase:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: _claseSeleccionada,
                              items: _clasesDisponibles
                                  .map<DropdownMenuItem<int>>((clase) {
                                return DropdownMenuItem<int>(
                                  value: clase['id'],
                                  child: Text(
                                    clase['nombre'] ?? 'Sin nombre',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _claseSeleccionada = value;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Selecciona una clase',
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
                            SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _claseSeleccionada != null
                                    ? _inscribirseAClase
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Inscribirse',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de inscripciones
                      Expanded(
                        child: inscripcionesActivas.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 60, color: Colors.grey[400]),
                                    SizedBox(height: 16),
                                    Text(
                                      'No tienes inscripciones activas',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '¡Inscríbete a una clase!',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: inscripcionesActivas.length,
                                itemBuilder: (context, index) {
                                  final insc = inscripcionesActivas[index];
                                  final claseId = insc['clase_id'];
                                  final nombreClase =
                                      _obtenerNombreClase(claseId);

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.fitness_center,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    size: 20,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    nombreClase,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            _buildInfoRow(
                                                'Inscrito el',
                                                _formatearFecha(
                                                    insc['fecha_inscripcion'])),
                                            _buildInfoRow(
                                                'Estado',
                                                _traducirEstado(
                                                    insc['estado'])),
                                            SizedBox(height: 16),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _mostrarDialogoCancelacion(
                                                        insc['id'],
                                                        nombreClase),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: Text(
                                                    'Cancelar inscripción'),
                                              ),
                                            ),
                                          ],
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
