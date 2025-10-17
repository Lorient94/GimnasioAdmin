import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Cubits/inscripcion_cubit.dart';
import '../Cubits/usuario_cubit.dart';
import '../Cubits/clase_cubit.dart';

class CrearInscripcionWidget extends StatefulWidget {
  final VoidCallback onCancelar;

  const CrearInscripcionWidget({Key? key, required this.onCancelar})
      : super(key: key);

  @override
  State<CrearInscripcionWidget> createState() => _CrearInscripcionWidgetState();
}

class _CrearInscripcionWidgetState extends State<CrearInscripcionWidget> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _datosInscripcion = {};
  dynamic _clienteSeleccionado;
  dynamic _claseSeleccionada;
  double? _precioSeleccionado;

  late List<Map<String, dynamic>> _clientes;
  late List<Map<String, dynamic>> _clases;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      // Obtener datos desde cubits
      final usuarioCubit = context.read<UsuarioCubit>();
      final claseCubit = context.read<ClaseCubit>();

      await usuarioCubit.cargarUsuarios(soloActivos: true);
      await claseCubit.cargarClases();

      setState(() {
        _clientes = (usuarioCubit.state as dynamic)
            .usuariosFiltrados
            .cast<Map<String, dynamic>>();
        _clases = (claseCubit.state as dynamic)
            .clasesFiltradas
            .cast<Map<String, dynamic>>();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  void _guardarInscripcion() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    const estadoMap = {
      'pendiente': 'pendiente',
      'activa': 'activo',
    };

    _datosInscripcion['cliente_dni'] = _clienteSeleccionado['dni'];
    _datosInscripcion['clase_id'] = _claseSeleccionada['id'];
    _datosInscripcion['precio'] = _precioSeleccionado ?? 0.0;
    _datosInscripcion['estado'] =
        estadoMap[_datosInscripcion['estado']] ?? 'pendiente'; // <-- aquí
    _datosInscripcion['pagado'] = false;
    _datosInscripcion['fecha_inscripcion'] = DateTime.now().toIso8601String();

    final cubit = context.read<InscripcionCubit>();
    await cubit.crearInscripcion(_datosInscripcion);

    if (mounted) widget.onCancelar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Crear Nueva Inscripción',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancelar,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<dynamic>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Cliente',
                      border: OutlineInputBorder(),
                    ),
                    items: _clientes.map((cliente) {
                      return DropdownMenuItem(
                        value: cliente,
                        child: Text("${cliente['nombre']} (${cliente['dni']})"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _clienteSeleccionado = value);
                    },
                    validator: (value) =>
                        value == null ? 'Seleccione un cliente' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<dynamic>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Clase',
                      border: OutlineInputBorder(),
                    ),
                    items: _clases.map((clase) {
                      return DropdownMenuItem(
                        value: clase,
                        child: Text("${clase['nombre']}"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _claseSeleccionada = value;
                        _precioSeleccionado = double.tryParse(
                                value['precio']?.toString() ?? '0') ??
                            0.0;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Seleccione una clase' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                        text: _precioSeleccionado?.toStringAsFixed(2) ?? ''),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    value: _datosInscripcion['estado'],
                    items: const [
                      DropdownMenuItem(
                          value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'activa', child: Text('Activa')),
                    ],
                    onChanged: (value) =>
                        _datosInscripcion['estado'] = value ?? 'pendiente',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _guardarInscripcion,
                          child: const Text('Crear Inscripción'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onCancelar,
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
