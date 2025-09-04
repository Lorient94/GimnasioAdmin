import 'package:flutter/material.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class EditarPerfilScreen extends StatefulWidget {
  final RepositorioAPI api;
  const EditarPerfilScreen({Key? key, required this.api}) : super(key: key);

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  Map<String, dynamic>? _datosUsuario;
  bool _cargando = true;
  String _error = '';
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _generoSeleccionado = '';
  final List<String> _opcionesGenero = ['', 'Femenino', 'Masculino', 'Otro'];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() => _cargando = true);
    try {
      final userData = await AuthService.getUserData();
      if (userData == null || userData['dni'] == null) {
        setState(() {
          _error = 'No se encontró el usuario autenticado';
          _cargando = false;
        });
        return;
      }
      final datos = await widget.api.obtenerClientes();
      final usuario = datos.firstWhere((c) => c['dni'] == userData['dni'],
          orElse: () => null);
      if (usuario == null) {
        setState(() {
          _error = 'Usuario no encontrado';
          _cargando = false;
        });
        return;
      }
      _datosUsuario = usuario;
      _nombreController.text = usuario['nombre'] ?? '';
      _telefonoController.text = usuario['telefono'] ?? '';
      _ciudadController.text = usuario['ciudad'] ?? '';
      _correoController.text = usuario['correo'] ?? '';
      _generoSeleccionado = usuario['genero'] ?? '';

      // Formatear fecha de nacimiento
      if (usuario['fecha_nacimiento'] != null) {
        final fecha = DateTime.parse(usuario['fecha_nacimiento']);
        _fechaNacimientoController.text =
            DateFormat('yyyy-MM-dd').format(fecha);
      }

      setState(() {
        _cargando = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // Permite fechas hasta hoy
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate() || _datosUsuario == null) return;

    // Validar contraseñas si se están cambiando
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La contraseña debe tener al menos 6 caracteres'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _cargando = true);
    try {
      final datosActualizados = {
        'nombre': _nombreController.text,
        'telefono': _telefonoController.text,
        'ciudad':
            _ciudadController.text.isNotEmpty ? _ciudadController.text : null,
        'correo': _correoController.text,
        'genero': _generoSeleccionado.isNotEmpty ? _generoSeleccionado : null,
        'fecha_nacimiento': _fechaNacimientoController.text.isNotEmpty
            ? _fechaNacimientoController.text
            : null,
      };

      // Agregar contraseña solo si se está cambiando
      if (_passwordController.text.isNotEmpty) {
        datosActualizados['password'] = _passwordController.text;
      }

      print('📤 Enviando datos: $datosActualizados');

      final response = await widget.api.actualizarCliente(
        _datosUsuario!['id'],
        datosActualizados,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Datos actualizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatosUsuario();

        // Limpiar campos de contraseña después de guardar
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        setState(() {
          _error = 'No se pudo actualizar';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al actualizar: $e';
      });
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
        backgroundColor: Colors.green[700],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Campo requerido'
                              : null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: _telefonoController,
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Campo requerido'
                              : null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: _ciudadController,
                          decoration: InputDecoration(
                            labelText: 'Ciudad',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: _correoController,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Campo requerido';
                            if (!value.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Género',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _generoSeleccionado,
                              isDense: true,
                              isExpanded: true,
                              items: _opcionesGenero.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.isEmpty
                                      ? 'Seleccionar género'
                                      : value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _generoSeleccionado = newValue ?? '';
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: _fechaNacimientoController,
                          decoration: InputDecoration(
                            labelText: 'Fecha de Nacimiento',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: _selectDate,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona tu fecha de nacimiento';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        Divider(thickness: 2),
                        SizedBox(height: 10),
                        Text(
                          'Cambiar Contraseña',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700]),
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Nueva Contraseña',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Deja en blanco si no quieres cambiar la contraseña',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _guardarCambios,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Guardar Cambios',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _ciudadController.dispose();
    _correoController.dispose();
    _fechaNacimientoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
