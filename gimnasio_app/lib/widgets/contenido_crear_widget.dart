import 'package:flutter/material.dart';

class ContenidoCrearForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onGuardar;
  final VoidCallback onCancelar;

  const ContenidoCrearForm({
    Key? key,
    required this.onGuardar,
    required this.onCancelar,
  }) : super(key: key);

  @override
  State<ContenidoCrearForm> createState() => _ContenidoCrearFormState();
}

class _ContenidoCrearFormState extends State<ContenidoCrearForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _urlArchivoController = TextEditingController();

  String _categoriaSeleccionada = 'general';
  String _tipoArchivoSeleccionado = 'documento';
  bool _activo = true;
  bool _esPublico = true;

  final List<String> _categorias = [
    'ejercicios',
    'nutricion',
    'rutinas',
    'tecnica',
    'salud',
    'general'
  ];

  final List<String> _tiposArchivo = [
    'imagen',
    'video',
    'pdf',
    'documento',
    'audio',
    'enlace'
  ];

  String _getTextoCategoria(String categoria) {
    switch (categoria) {
      case 'ejercicios':
        return 'Ejercicios';
      case 'nutricion':
        return 'Nutrición';
      case 'rutinas':
        return 'Rutinas';
      case 'tecnica':
        return 'Técnica';
      case 'salud':
        return 'Salud';
      case 'general':
        return 'General';
      default:
        return categoria;
    }
  }

  String _getTextoTipoArchivo(String tipo) {
    switch (tipo) {
      case 'imagen':
        return 'Imagen';
      case 'video':
        return 'Video';
      case 'pdf':
        return 'PDF';
      case 'documento':
        return 'Documento';
      case 'audio':
        return 'Audio';
      case 'enlace':
        return 'Enlace';
      default:
        return tipo;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _urlArchivoController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final datosContenido = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'categoria': _categoriaSeleccionada,
        'tipo_archivo': _tipoArchivoSeleccionado,
        'url_archivo': _urlArchivoController.text.trim(),
        'activo': _activo,
        'es_publico': _esPublico,
      };

      widget.onGuardar(datosContenido);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Contenido'),
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
                  hintText: 'Ingrese el título del contenido',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(
                      _getTextoCategoria(categoria),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tipo de Archivo
              DropdownButtonFormField<String>(
                value: _tipoArchivoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Archivo *',
                  border: OutlineInputBorder(),
                ),
                items: _tiposArchivo.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(
                      _getTextoTipoArchivo(tipo),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoArchivoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // URL del Archivo
              TextFormField(
                controller: _urlArchivoController,
                decoration: const InputDecoration(
                  labelText: 'URL del Archivo',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese la URL del archivo (opcional)',
                ),
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese la descripción del contenido',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Estado activo/inactivo
              SwitchListTile(
                title: const Text('Contenido Activo'),
                subtitle: const Text(
                    'El contenido estará disponible para los usuarios'),
                value: _activo,
                onChanged: (value) {
                  setState(() {
                    _activo = value;
                  });
                },
              ),

              // Contenido público/privado
              SwitchListTile(
                title: const Text('Contenido Público'),
                subtitle: const Text(
                    'El contenido será visible para todos los usuarios'),
                value: _esPublico,
                onChanged: (value) {
                  setState(() {
                    _esPublico = value;
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
                    child: const Text('Guardar Contenido'),
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
