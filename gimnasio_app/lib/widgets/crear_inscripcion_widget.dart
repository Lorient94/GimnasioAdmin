// widgets/crear_inscripcion_widget.dart
import 'package:flutter/material.dart';

class CrearInscripcionWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onGuardar;
  final VoidCallback onCancelar;

  const CrearInscripcionWidget({
    Key? key,
    required this.onGuardar,
    required this.onCancelar,
  }) : super(key: key);

  @override
  State<CrearInscripcionWidget> createState() => _CrearInscripcionWidgetState();
}

class _CrearInscripcionWidgetState extends State<CrearInscripcionWidget> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _datosInscripcion = {};

  @override
  Widget build(BuildContext context) {
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
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'DNI del Cliente',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el DNI';
                      }
                      return null;
                    },
                    onSaved: (value) =>
                        _datosInscripcion['cliente_dni'] = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'ID de la Clase',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el ID de la clase';
                      }
                      return null;
                    },
                    onSaved: (value) => _datosInscripcion['clase_id'] =
                        int.tryParse(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el precio';
                      }
                      return null;
                    },
                    onSaved: (value) => _datosInscripcion['precio'] =
                        double.tryParse(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'activa', child: Text('Activa')),
                    ],
                    onChanged: (value) => _datosInscripcion['estado'] = value,
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor seleccione un estado';
                      }
                      return null;
                    },
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

  void _guardarInscripcion() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onGuardar(_datosInscripcion);
    }
  }
}
