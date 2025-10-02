// widgets/crear_informacion_widget.dart
import 'package:flutter/material.dart';

class CrearInformacionWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onGuardar;
  final VoidCallback onCancelar;

  const CrearInformacionWidget({
    Key? key,
    required this.onGuardar,
    required this.onCancelar,
  }) : super(key: key);

  @override
  State<CrearInformacionWidget> createState() => _CrearInformacionWidgetState();
}

class _CrearInformacionWidgetState extends State<CrearInformacionWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  final TextEditingController _destinatarioController = TextEditingController();

  String _tipoSeleccionado = 'noticia';
  bool _activa = true;
  DateTime? _fechaExpiracion;

  final List<String> _tipos = [
    'noticia',
    'anuncio',
    'evento',
    'promocion',
    'general'
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _destinatarioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaExpiracion() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaExpiracion = fechaSeleccionada;
      });
    }
  }

  void _limpiarFechaExpiracion() {
    setState(() {
      _fechaExpiracion = null;
    });
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final datosInformacion = {
        'titulo': _tituloController.text.trim(),
        'contenido': _contenidoController.text.trim(),
        'tipo': _tipoSeleccionado,
        'activa': _activa,
        if (_destinatarioController.text.isNotEmpty)
          'destinatario': _destinatarioController.text.trim(),
        if (_fechaExpiracion != null)
          'fecha_expiracion': _fechaExpiracion!.toIso8601String(),
      };

      widget.onGuardar(datosInformacion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Información'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardar,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese el título de la información',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(),
                ),
                items: _tipos.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(
                      tipo.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Contenido
              TextFormField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  labelText: 'Contenido *',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese el contenido de la información',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El contenido es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Destinatario (opcional)
              TextFormField(
                controller: _destinatarioController,
                decoration: const InputDecoration(
                  labelText: 'Destinatario (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'DNI o grupo destinatario',
                ),
              ),
              const SizedBox(height: 16),

              // Fecha de expiración
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Expiración (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _fechaExpiracion != null
                            ? '${_fechaExpiracion!.day}/${_fechaExpiracion!.month}/${_fechaExpiracion!.year}'
                            : 'No establecida',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _seleccionarFechaExpiracion,
                    tooltip: 'Seleccionar fecha',
                  ),
                  if (_fechaExpiracion != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: _limpiarFechaExpiracion,
                      tooltip: 'Limpiar fecha',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Estado activo/inactivo
              SwitchListTile(
                title: const Text('Información Activa'),
                subtitle: const Text(
                    'La información será visible para los destinatarios'),
                value: _activa,
                onChanged: (value) {
                  setState(() {
                    _activa = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancelar,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar Información'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
