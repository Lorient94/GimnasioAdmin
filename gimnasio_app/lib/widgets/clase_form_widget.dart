// widgets/clase_form_widget.dart
import 'package:flutter/material.dart';

class ClaseFormWidget extends StatefulWidget {
  final Map<String, dynamic>? clase;
  final Function(Map<String, dynamic>) onGuardar;

  const ClaseFormWidget({
    Key? key,
    this.clase,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ClaseFormWidget> createState() => _ClaseFormWidgetState();
}

class _ClaseFormWidgetState extends State<ClaseFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _instructorController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _horarioController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _duracionController = TextEditingController();
  final _precioController = TextEditingController();

  String _dificultad = 'principiante';
  bool _activa = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosExistentes();
  }

  void _cargarDatosExistentes() {
    if (widget.clase != null) {
      _nombreController.text = widget.clase!['nombre'] ?? '';
      _instructorController.text = widget.clase!['instructor'] ?? '';
      _descripcionController.text = widget.clase!['descripcion'] ?? '';
      _horarioController.text = widget.clase!['horario'] ?? '';
      _capacidadController.text = widget.clase!['capacidad']?.toString() ?? '';
      _duracionController.text =
          widget.clase!['duracion_minutos']?.toString() ?? '';
      _precioController.text = widget.clase!['precio']?.toString() ?? '';
      _dificultad = widget.clase!['dificultad'] ?? 'principiante';
      _activa = widget.clase!['activa'] ?? true;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _instructorController.dispose();
    _descripcionController.dispose();
    _horarioController.dispose();
    _capacidadController.dispose();
    _duracionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _guardarClase() {
    if (_formKey.currentState!.validate()) {
      final datosClase = {
        'nombre': _nombreController.text,
        'instructor': _instructorController.text,
        'descripcion': _descripcionController.text,
        'horario': _horarioController.text,
        'capacidad': int.parse(_capacidadController.text),
        'duracion_minutos': int.parse(_duracionController.text),
        'precio': double.parse(_precioController.text),
        'dificultad': _dificultad,
        'activa': _activa,
      };

      widget.onGuardar(datosClase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la clase',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre de la clase';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructorController,
              decoration: const InputDecoration(
                labelText: 'Instructor',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre del instructor';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _horarioController,
              decoration: const InputDecoration(
                labelText: 'Horario',
                border: OutlineInputBorder(),
                hintText: 'Ej: Lunes y Miércoles 18:00-19:00',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el horario';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capacidadController,
                    decoration: const InputDecoration(
                      labelText: 'Capacidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la capacidad';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Por favor ingresa un número válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _duracionController,
                    decoration: const InputDecoration(
                      labelText: 'Duración (minutos)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la duración';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Por favor ingresa un número válido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el precio';
                }
                if (double.tryParse(value) == null) {
                  return 'Por favor ingresa un precio válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _dificultad,
              decoration: const InputDecoration(
                labelText: 'Dificultad',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'principiante', child: Text('Principiante')),
                DropdownMenuItem(
                    value: 'intermedio', child: Text('Intermedio')),
                DropdownMenuItem(value: 'avanzado', child: Text('Avanzado')),
              ],
              onChanged: (value) {
                setState(() {
                  _dificultad = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Clase activa'),
              value: _activa,
              onChanged: (value) {
                setState(() {
                  _activa = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _guardarClase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
