import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../repositorio_api/repositorio_api.dart';
import 'registroUsuario.dart';

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
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      final userData = await AuthService.getUserData();
      setState(() {
        _isLoggedIn = true;
        _userData = userData;
      });
    }
  }

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

      print('Respuesta login: $response');

      if (response != null && response['dni'] != null) {
        await AuthService.saveUserData(response);

        setState(() {
          _isLoggedIn = true;
          _userData = response;
          _cargando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Sesión iniciada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else if (response != null && response['detail'] != null) {
        setState(() {
          _error = response['detail'];
          _cargando = false;
        });
      } else {
        setState(() {
          _error = 'Credenciales incorrectas o cuenta inactiva';
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    setState(() {
      _cargando = true;
    });

    await AuthService.logout();

    setState(() {
      _isLoggedIn = false;
      _userData = null;
      _correoController.clear();
      _passwordController.clear();
      _cargando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Sesión cerrada correctamente'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _isLoggedIn
            ? [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: _cerrarSesion,
                  tooltip: 'Cerrar sesión',
                ),
              ]
            : null,
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: _isLoggedIn ? _buildUserProfile() : _buildLoginForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        SizedBox(height: 20),
        Text(
          '¡Bienvenido/a!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 8),
        if (_userData != null && _userData!['nombre'] != null)
          Text(
            _userData!['nombre'],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        SizedBox(height: 4),
        if (_userData != null && _userData!['correo'] != null)
          Text(
            _userData!['correo'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cerrarSesion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _cargando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
          child: Text(
            'Volver al Inicio',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
              Icons.fitness_center,
              size: 50,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 30),
          Text(
            'Bienvenido a Gimnasio ABC',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ingresa a tu cuenta para continuar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 30),
          TextFormField(
            controller: _correoController,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              labelStyle: TextStyle(
                color: Colors.grey[600],
              ),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              // Añadido para mejor contraste
              floatingLabelStyle: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _verificarCredenciales(),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Ingresa tu correo electrónico';
              if (!value.contains('@')) return 'Correo electrónico inválido';
              return null;
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              labelStyle: TextStyle(
                color: Colors.grey[600],
              ),
              prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey[600]),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              // Añadido para mejor contraste
              floatingLabelStyle: TextStyle(
                color: Theme.of(context).primaryColor,
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
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cargando ? null : _iniciarSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _cargando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegistroUsuarioScreen(api: widget.api),
                ),
              );
            },
            child: RichText(
              text: TextSpan(
                text: '¿No tienes cuenta? ',
                style: TextStyle(color: Colors.grey[700]),
                children: [
                  TextSpan(
                    text: 'Regístrate aquí',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Aquí podrías implementar la funcionalidad de recuperar contraseña
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Contacta con administración para recuperar tu contraseña'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
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
