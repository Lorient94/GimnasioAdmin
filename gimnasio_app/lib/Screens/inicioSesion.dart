import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../repositorio_api/repositorio_api.dart';

class InicioSesionScreen extends StatefulWidget {
  final RepositorioAPI api;

  const InicioSesionScreen({Key? key, required this.api}) : super(key: key);

  @override
  _InicioSesionScreenState createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _cargando = false;
  bool _passwordVisible = false;
  String _error = '';

  final Color green500 = Color(0xFF4CAF50);
  final Color green600 = Color(0xFF43A047);
  final Color green700 = Color(0xFF388E3C);
  final Color green800 = Color(0xFF2E7D32);
  final Color grey100 = Color(0xFFF5F5F5);

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final response = await widget.api.loginCliente(
        _correoController.text,
        _passwordController.text,
      );

      print('Respuesta login: $response'); // <-- logging

      if (response != null && response['dni'] != null) {
        await AuthService.saveUserData(response);

        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else if (response != null && response['detail'] != null) {
        setState(() {
          _error = response['detail'];
        });
      } else {
        setState(() {
          _error = 'Credenciales incorrectas o cuenta inactiva';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _verificarCredenciales() async {
    if (_correoController.text.isEmpty) return;

    try {
      final existe = await widget.api.autenticarCorreo(_correoController.text);
      if (!existe) {
        setState(() {
          _error = 'Este correo no está registrado';
        });
      } else {
        setState(() {
          _error = '';
        });
      }
    } catch (e) {
      // Ignorar errores de verificación
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar Sesión'),
        backgroundColor: green700,
      ),
      body: Container(
        color: grey100,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Icon(Icons.person, size: 100, color: green500),
                    SizedBox(height: 30),
                    TextFormField(
                      controller: _correoController,
                      decoration:
                          InputDecoration(labelText: 'Correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _verificarCredenciales(),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Ingresa tu correo';
                        if (!value.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(
                                () => _passwordVisible = !_passwordVisible);
                          },
                        ),
                      ),
                      obscureText: !_passwordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Ingresa tu contraseña';
                        if (value.length < 4) return 'Mínimo 4 caracteres';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    if (_error.isNotEmpty)
                      Text(_error, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _iniciarSesion,
                        child: _cargando
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Iniciar Sesión'),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/registro'),
                      child: Text('¿No tienes cuenta? Regístrate aquí'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
