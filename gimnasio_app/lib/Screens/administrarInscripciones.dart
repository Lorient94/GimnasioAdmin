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
      final inscripciones =
          await widget.api.obtenerInscripciones(clienteDni: _clienteDni);
      final clases = await widget.api.obtenerClases();
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
              content: Text('Inscripción realizada correctamente'),
              backgroundColor: Colors.green),
        );
        await _cargarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No se pudo inscribir'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarDialogoCancelacion(int inscripcionId) async {
    final motivoController = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar cancelación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Estás seguro de que quieres cancelar esta inscripción?'),
              SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo de cancelación',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: No puedo asistir, cambio de horario...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (motivoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor ingresa un motivo')),
                  );
                  return;
                }
                Navigator.pop(context, motivoController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
              content: Text('Inscripción cancelada exitosamente'),
              backgroundColor: Colors.orange),
        );
        await _cargarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No se pudo cancelar la inscripción'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al cancelar: $e'),
            backgroundColor: Colors.red),
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

  // NUEVO MÉTODO: Obtener nombre de la clase desde la lista de clases disponibles
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
    // Filtrar solo inscripciones activas
    final inscripcionesActivas = _inscripciones.where((insc) {
      final estado = insc['estado']?.toString() ?? '';
      return estado == 'activo';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Inscripciones Activas'),
        backgroundColor: Colors.blue[700],
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
              : Column(
                  children: [
                    // Sección para inscribirse a nuevas clases
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Inscribirse a una clase:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButtonFormField<int>(
                            value: _claseSeleccionada,
                            items: _clasesDisponibles
                                .map<DropdownMenuItem<int>>((clase) {
                              return DropdownMenuItem<int>(
                                value: clase['id'],
                                child: Text(clase['nombre'] ?? 'Sin nombre'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _claseSeleccionada = value;
                              });
                            },
                            decoration: InputDecoration(
                                labelText: 'Selecciona una clase'),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _cargando ? null : _inscribirseAClase,
                            child: Text('Inscribirse'),
                          ),
                        ],
                      ),
                    ),

                    // Lista de inscripciones ACTIVAS solamente
                    Expanded(
                      child: inscripcionesActivas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No tienes inscripciones activas',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey)),
                                  Text('¡Inscríbete a una clase!',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: inscripcionesActivas.length,
                              itemBuilder: (context, index) {
                                final insc = inscripcionesActivas[index];
                                final claseId = insc['clase_id'];
                                final nombreClase =
                                    _obtenerNombreClase(claseId);

                                return Card(
                                  margin: EdgeInsets.all(8),
                                  child: ListTile(
                                    leading: Icon(Icons.fitness_center,
                                        color: Colors.blue),
                                    title: Text(nombreClase,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Fecha: ${_formatearFecha(insc['fecha_inscripcion'])}'),
                                        Text(
                                            'Estado: ${_traducirEstado(insc['estado'])}'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon:
                                          Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () =>
                                          _mostrarDialogoCancelacion(
                                              insc['id']),
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
