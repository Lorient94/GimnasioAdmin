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
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

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
      initialDate: _fechaNacimientoController.text.isNotEmpty
          ? DateTime.parse(_fechaNacimientoController.text)
          : DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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

    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La contraseña debe tener al menos 6 caracteres'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

      if (_passwordController.text.isNotEmpty) {
        datosActualizados['password'] = _passwordController.text;
      }

      final response = await widget.api.actualizarCliente(
        _datosUsuario!['id'],
        datosActualizados,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Datos actualizados correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        await _cargarDatosUsuario();
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
        title: Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
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
                          onPressed: _cargarDatosUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Header con avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Editar Información Personal',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Actualiza tus datos personales',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 32),

                          // Campos del formulario
                          _buildTextField(
                            controller: _nombreController,
                            label: 'Nombre completo',
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo requerido'
                                : null,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _telefonoController,
                            label: 'Teléfono',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo requerido'
                                : null,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _ciudadController,
                            label: 'Ciudad',
                            icon: Icons.location_city_outlined,
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _correoController,
                            label: 'Correo electrónico',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Campo requerido';
                              if (!value.contains('@'))
                                return 'Correo inválido';
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildDropdownGenero(),
                          SizedBox(height: 16),
                          _buildDatePickerField(),
                          SizedBox(height: 24),

                          // Sección de contraseña
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lock_outline,
                                        color: Colors.blue[700], size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cambiar Contraseña',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Deja en blanco si no deseas cambiar la contraseña',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildPasswordField(
                                  controller: _passwordController,
                                  label: 'Nueva Contraseña',
                                  isVisible: _passwordVisible,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                                SizedBox(height: 12),
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirmar Contraseña',
                                  isVisible: _confirmPasswordVisible,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _confirmPasswordVisible =
                                          !_confirmPasswordVisible;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),

                          // Botón de guardar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _guardarCambios,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _cargando
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Guardar Cambios',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[700], // Color más oscuro para mejor visibilidad
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).primaryColor, // Color cuando está enfocado
        ),
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[700], // Color más oscuro
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600], size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdownGenero() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Género',
        labelStyle: TextStyle(
          color: Colors.grey[700], // Color más oscuro
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        prefixIcon:
            Icon(Icons.people_outline, color: Colors.grey[600], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _generoSeleccionado,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          items: _opcionesGenero.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value.isEmpty ? 'Seleccionar género' : value,
                style: TextStyle(color: Colors.grey[800]),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _generoSeleccionado = newValue ?? '';
            });
          },
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return TextFormField(
      controller: _fechaNacimientoController,
      readOnly: true,
      onTap: _selectDate,
      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
      decoration: InputDecoration(
        labelText: 'Fecha de Nacimiento',
        labelStyle: TextStyle(
          color: Colors.grey[700], // Color más oscuro
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
        prefixIcon: Icon(Icons.calendar_today_outlined,
            color: Colors.grey[600], size: 20),
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_today, color: Colors.grey[600]),
          onPressed: _selectDate,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona tu fecha de nacimiento';
        }
        return null;
      },
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
