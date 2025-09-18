import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';

class RegistroUsuarioScreen extends StatefulWidget {
  final RepositorioAPI api;
  const RegistroUsuarioScreen({super.key, required this.api});

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();

  bool _isLoading = false;

  final FocusNode _dniFocusNode = FocusNode();
  final FocusNode _fechaFocusNode = FocusNode();
  final FocusNode _telefonoFocusNode = FocusNode();
  final FocusNode _correoFocusNode = FocusNode();
  final FocusNode _ciudadFocusNode = FocusNode();

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _fechaNacimientoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _ciudadController.dispose();

    _dniFocusNode.dispose();
    _fechaFocusNode.dispose();
    _telefonoFocusNode.dispose();
    _correoFocusNode.dispose();
    _ciudadFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 350;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[800]!,
                    Colors.blue[600]!,
                    Colors.blue[400]!
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(isSmallScreen),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildLoginLink(),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              _buildFormFields(isSmallScreen),
                              SizedBox(height: isSmallScreen ? 20 : 24),
                              _buildRegisterButton(isSmallScreen),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) => Column(
        children: [
          Icon(Icons.fitness_center,
              size: isSmallScreen ? 50 : 60, color: Colors.white),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Text('GYM ABC',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          SizedBox(height: isSmallScreen ? 5 : 8),
          Text('Crear nueva cuenta',
              style: TextStyle(
                  color: Colors.white70, fontSize: isSmallScreen ? 16 : 18)),
        ],
      );

  Widget _buildLoginLink() => GestureDetector(
        onTap: () {
          Navigator.pop(context); // Volver a login
        },
        child: RichText(
          text: TextSpan(
            text: '¿Ya tienes usuario? ',
            style: const TextStyle(color: Colors.grey, fontSize: 15),
            children: <TextSpan>[
              TextSpan(
                  text: 'Inicia sesión aquí',
                  style: TextStyle(
                      color: Colors.blue[700], fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _buildFormFields(bool isSmallScreen) => Column(
        children: [
          _buildTextField(
            controller: _nombreController,
            label: 'NOMBRE',
            icon: Icons.person,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_dniFocusNode),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Por favor ingresa tu nombre';
              if (value.length < 3)
                return 'El nombre debe tener al menos 3 caracteres';
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(
            controller: _dniController,
            focusNode: _dniFocusNode,
            label: 'DNI',
            icon: Icons.badge,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8)
            ],
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_fechaFocusNode),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Por favor ingresa tu DNI';
              if (value.length != 8) return 'El DNI debe tener 8 dígitos';
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildDatePickerField(isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(
            controller: _telefonoController,
            focusNode: _telefonoFocusNode,
            label: 'TELÉFONO',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9)
            ],
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_correoFocusNode),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Por favor ingresa tu teléfono';
              if (value.length != 9) return 'El teléfono debe tener 9 dígitos';
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(
            controller: _correoController,
            focusNode: _correoFocusNode,
            label: 'CORREO ELECTRÓNICO',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_ciudadFocusNode),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Por favor ingresa tu correo electrónico';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                return 'Por favor ingresa un correo válido';
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(
            controller: _ciudadController,
            focusNode: _ciudadFocusNode,
            label: 'CIUDAD',
            icon: Icons.location_city,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _registrarUsuario(),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Por favor ingresa tu ciudad';
              return null;
            },
          ),
        ],
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2)),
      ),
      validator: validator,
    );
  }

  Widget _buildDatePickerField(bool isSmallScreen) {
    return TextFormField(
      controller: _fechaNacimientoController,
      focusNode: _fechaFocusNode,
      readOnly: true,
      onTap: _selectDate,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_telefonoFocusNode),
      decoration: InputDecoration(
        labelText: 'FECHA DE NACIMIENTO',
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty)
          return 'Por favor selecciona tu fecha de nacimiento';
        return null;
      },
    );
  }

  Widget _buildRegisterButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registrarUsuario,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
              horizontal: 24, vertical: isSmallScreen ? 14 : 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2),
              )
            : Text('Registrarme',
                style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 12)),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final cliente = {
        'dni': _dniController.text,
        'nombre': _nombreController.text,
        'fecha_nacimiento': _fechaNacimientoController.text,
        'telefono': _telefonoController.text,
        'correo': _correoController.text,
        'ciudad': _ciudadController.text,
        'password': _dniController.text, // La contraseña es el DNI
        'activo': true
      };

      print('📤 Enviando al backend: $cliente');

      final response = await widget.api.crearCliente(cliente);

      print('📥 Respuesta del backend: $response');

      if (response != null && response['dni'] != null) {
        print('✅ Registro exitoso');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Registro exitoso. Tu contraseña es tu DNI.'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );

        // Limpiar formulario
        _formKey.currentState!.reset();
        Navigator.pop(context); // Volver al login después de registro exitoso
      } else {
        print('❌ Error del servidor: respuesta inesperada');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Error del servidor - respuesta inesperada'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on DioException catch (e) {
      print('❌ ERROR Dio: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        // Error de validación del backend
        final errorData = e.response?.data;
        String errorMessage = 'Error de validación';

        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail'];
          } else if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error de conexión: ${e.message}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ ERROR INESPERADO: $e');
      print('StackTrace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error inesperado: $e'),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
