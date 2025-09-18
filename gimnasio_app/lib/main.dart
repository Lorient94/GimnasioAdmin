// main.dart - Versión optimizada
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  RepositorioAPI api;

  try {
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
    api = RepositorioAPI(baseUrl: 'http://192.168.1.16:8000');
  }

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
      title: 'Gimnasio ABC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1A73E8),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Color(0xFF34A853),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1A73E8),
          elevation: 2,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF1A73E8),
            textStyle: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF1A73E8),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF1A73E8),
          secondary: Color(0xFF34A853),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      // CAMBIO PRINCIPAL: Siempre inicia con HomeScreen
      home: HomeScreen(api: api),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A73E8).withOpacity(0.9),
              Color(0xFF34A853).withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    size: 60,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Bienvenido a Gimnasio ABC',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Tu compañero fitness para alcanzar tus metas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: options.map((option) {
                      return _buildMenuCard(context, option);
                    }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  '© 2025 Gimnasio ABC',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuOption option) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, option.route);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 32,
                color: Color(0xFF1A73E8),
              ),
              SizedBox(height: 12),
              Text(
                option.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
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
