// main.dart
import 'package:flutter/material.dart';
import 'Screens/inicioSesion.dart';
import 'Screens/registroUsuario.dart';
import 'Screens/editarPerfil.dart';
import 'Screens/verClases.dart';
import 'Screens/verContenido.dart';
import 'Screens/verInformacion.dart';
import 'Screens/administrarInscripciones.dart';
import 'Screens/cronogramaClases.dart';
import 'repositorio_api/repositorio_api.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  RepositorioAPI api;

  try {
    // Intenta encontrar la IP automáticamente
    print('🔍 Buscando servidor automáticamente...');
    api = await RepositorioAPI.createWithAutoIP();

    final connection = await api.testConnection();
    if (connection['connected'] == true) {
      print('✅ Conexión exitosa: ${api.baseUrl}');
    } else {
      print('⚠️  Usando IP por defecto');
      api = RepositorioAPI(baseUrl: 'http://192.168.1.16:8000');
    }
  } catch (e) {
    print('❌ Error auto-detectando IP: $e');
    // Fallback a IP por defecto
    api = RepositorioAPI(baseUrl: 'http://192.168.1.16:8000');
  }

  // Test final de conexión
  final isConnected = await api.testConnection();
  print('Connection status: $isConnected');

  runApp(MyApp(api: api));
}

class MyApp extends StatelessWidget {
  final RepositorioAPI api;

  const MyApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gimnasio App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return HomeScreen(api: api);
          }
          return InicioSesionScreen(api: api);
        },
      ),
      routes: {
        '/registro': (context) => RegistroUsuarioScreen(api: api),
        '/login': (context) => InicioSesionScreen(api: api),
        '/editarPerfil': (context) => EditarPerfilScreen(api: api),
        '/verClases': (context) => VerClasesScreen(api: api),
        '/verContenido': (context) => VerContenidoScreen(api: api),
        '/informacion': (context) => VerInformacionScreen(api: api),
        '/administrarInscripciones': (context) =>
            AdministrarInscripcionesScreen(api: api),
        '/cronogramaClases': (context) => CronogramaClasesScreen(api: api),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final RepositorioAPI api;

  HomeScreen({super.key, required this.api});

  final List<_MenuOption> options = [
    _MenuOption('Crear Usuario', Icons.person_add, '/registro'),
    _MenuOption('Iniciar Sesión', Icons.login, '/login'),
    _MenuOption('Editar Perfil', Icons.edit, '/editarPerfil'),
    _MenuOption('Ver Clases', Icons.fitness_center, '/verClases'),
    _MenuOption('Ver Contenido', Icons.video_library, '/verContenido'),
    _MenuOption('Información', Icons.info, '/informacion'),
    _MenuOption('Administrar Inscripciones', Icons.assignment,
        '/administrarInscripciones'),
    _MenuOption(
        'Cronograma de Clases', Icons.calendar_today, '/cronogramaClases'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.green[100]!,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Bienvenido al Gimnasio ABC',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Selecciona una opción para continuar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  ...options.map((option) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _buildButton(
                          context,
                          option.text,
                          option.icon,
                          Colors.green[600]!,
                          Colors.white,
                          () {
                            Navigator.pushNamed(context, option.route);
                          },
                        ),
                      )),
                  SizedBox(height: 30),
                  Text(
                    '2025 Gimnasio ABC',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: Colors.green.withOpacity(0.3),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuOption {
  final String text;
  final IconData icon;
  final String route;

  _MenuOption(this.text, this.icon, this.route);
}
