// main.dart - Usando repositorios específicos existentes
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// Importaciones de screens (usa las que existen en lib/Screens)
import 'Screens/clase_screen.dart';
import 'Screens/inscripciones_screen.dart';

// Importaciones de repositorios específicos (usando los que ya tienes)
import 'repositorio_api/clase_repositorio.dart';
import 'repositorio_api/contenido_repositorio.dart';
import 'repositorio_api/informacion_repositorio.dart';
import 'repositorio_api/inscripcion_repositorio.dart';
import 'repositorio_api/mercado_pago_repositorio.dart';
import 'repositorio_api/transaccion_repositorio.dart';
import 'repositorio_api/usuario_repositorio.dart';

// Importaciones de cubits
import 'Cubits/inscripcion_cubit.dart';
import 'Cubits/clase_cubit.dart';
import 'Cubits/contenido_cubit.dart';
import 'Cubits/informacion_cubit.dart';
import 'Cubits/mercado_pago_cubit.dart';
import 'Cubits/transaccion_cubit.dart';
import 'Cubits/usuario_cubit.dart';
// Screen de contenido
import 'Screens/contenido_screen.dart';
import 'Screens/informacion_screen.dart';
import 'Screens/pago_screen.dart';
import 'Screens/transacciones_screen.dart';
import 'Screens/usuarios_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // Configuración de Dio
  final dio = Dio();
  // Use localhost for local development. If you're testing from another device
  // on the same LAN, replace with the host IP (e.g. 'http://192.168.0.102:8000').
  final baseUrl = 'http://127.0.0.1:8000';

  // Inicializar todos los repositorios específicos
  final claseRepository = ClaseRepository(dio: dio, baseUrl: baseUrl);
  final inscripcionRepository =
      InscripcionRepository(dio: dio, baseUrl: baseUrl);
  final usuarioRepository = UsuarioRepository(dio: dio, baseUrl: baseUrl);
  final contenidoRepository = ContenidoRepository(dio: dio, baseUrl: baseUrl);
  final informacionRepository =
      InformacionRepository(dio: dio, baseUrl: baseUrl);
  final mercadoPagoRepository =
      MercadoPagoRepository(dio: dio, baseUrl: baseUrl);
  final transaccionRepository =
      TransaccionRepository(dio: dio, baseUrl: baseUrl);

  // Test de conexión básico
  try {
    final response = await dio.get('$baseUrl/');
    print('✅ Conexión exitosa: ${response.statusCode}');
  } catch (e) {
    print('❌ Error de conexión: $e');
  }

  runApp(MyApp(
    claseRepository: claseRepository,
    inscripcionRepository: inscripcionRepository,
    usuarioRepository: usuarioRepository,
    contenidoRepository: contenidoRepository,
    informacionRepository: informacionRepository,
    mercadoPagoRepository: mercadoPagoRepository,
    transaccionRepository: transaccionRepository,
  ));
}

class MyApp extends StatelessWidget {
  final ClaseRepository claseRepository;
  final InscripcionRepository inscripcionRepository;
  final UsuarioRepository usuarioRepository;
  final ContenidoRepository contenidoRepository;
  final InformacionRepository informacionRepository;
  final MercadoPagoRepository mercadoPagoRepository;
  final TransaccionRepository transaccionRepository;

  const MyApp({
    super.key,
    required this.claseRepository,
    required this.inscripcionRepository,
    required this.usuarioRepository,
    required this.contenidoRepository,
    required this.informacionRepository,
    required this.mercadoPagoRepository,
    required this.transaccionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ClaseCubit>(
          create: (context) => ClaseCubit(repository: claseRepository),
        ),
        BlocProvider<InscripcionCubit>(
          create: (context) =>
              InscripcionCubit(repository: inscripcionRepository),
        ),
        BlocProvider<ContenidoCubit>(
          create: (context) => ContenidoCubit(repository: contenidoRepository),
        ),
        BlocProvider<InformacionCubit>(
          create: (context) =>
              InformacionCubit(repository: informacionRepository),
        ),
        BlocProvider<MercadoPagoCubit>(
          create: (context) =>
              MercadoPagoCubit(repository: mercadoPagoRepository),
        ),
        BlocProvider<UsuarioCubit>(
          create: (context) => UsuarioCubit(repository: usuarioRepository),
        ),
        BlocProvider<TransaccionCubit>(
          create: (context) =>
              TransaccionCubit(repository: transaccionRepository),
        ),
        // Si tienes cubits/ blocs para usuario y contenido, agrégalos aquí.
        // Por ahora mantenemos los repositorios disponibles y las pantallas
      ],
      child: MaterialApp(
        title: 'Gimnasio ABC - Sistema de Gestión',
        theme: _buildTheme(),
        darkTheme: _buildDarkTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        home: HomeScreen(
          claseRepository: claseRepository,
          inscripcionRepository: inscripcionRepository,
          usuarioRepository: usuarioRepository,
          contenidoRepository: contenidoRepository,
          informacionRepository: informacionRepository,
          mercadoPagoRepository: mercadoPagoRepository,
          transaccionRepository: transaccionRepository,
        ),
        routes: {
          '/usuario': (context) => const UsuariosScreen(),
          '/clases': (context) => ClaseScreen(),
          '/inscripciones': (context) => InscripcionesScreen(),
          '/informacion': (context) => InformacionScreen(),
          '/contenido': (context) => ContenidoScreen(),
          '/pagos': (context) => PagoScreen(),
          '/transacciones': (context) => TransaccionesScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Color(0xFF1A73E8),
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
          .copyWith(secondary: Color(0xFF34A853)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: Color(0xFF1A73E8),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF1A73E8),
        secondary: Color(0xFF34A853),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final ClaseRepository claseRepository;
  final InscripcionRepository inscripcionRepository;
  final UsuarioRepository usuarioRepository;
  final ContenidoRepository contenidoRepository;
  final InformacionRepository informacionRepository;
  final MercadoPagoRepository mercadoPagoRepository;
  final TransaccionRepository transaccionRepository;

  HomeScreen({
    super.key,
    required this.claseRepository,
    required this.inscripcionRepository,
    required this.usuarioRepository,
    required this.contenidoRepository,
    required this.informacionRepository,
    required this.mercadoPagoRepository,
    required this.transaccionRepository,
  });

  static const List<_MenuOption> options = [
    _MenuOption('Usuario', Icons.person, '/usuario', Colors.blue),
    _MenuOption('Clases', Icons.fitness_center, '/clases', Colors.green),
    _MenuOption(
        'Inscripciones', Icons.assignment, '/inscripciones', Colors.orange),
    _MenuOption('Información', Icons.info, '/informacion', Colors.purple),
    _MenuOption('Contenido', Icons.video_library, '/contenido', Colors.red),
    _MenuOption('Pagos', Icons.payment, '/pagos', Colors.teal),
    _MenuOption(
        'Transacciones', Icons.history, '/transacciones', Colors.indigo),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sistema de Gestión - Gimnasio ABC'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A73E8).withOpacity(0.1),
              Color(0xFF34A853).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                SizedBox(height: 24),

                // Título de sección
                _buildSectionTitle(),
                SizedBox(height: 16),

                // Grid de opciones
                Expanded(child: _buildOptionsGrid(context)),

                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFF1A73E8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.fitness_center, size: 32, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gimnasio ABC',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sistema Integral de Gestión',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        'Módulos del Sistema',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children:
          options.map((option) => _buildMenuCard(context, option)).toList(),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        SizedBox(height: 20),
        Center(
          child: Text(
            '© 2025 Gimnasio ABC - v1.0.0',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuOption option) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, option.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                option.color.withOpacity(0.1),
                option.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: option.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(option.icon, size: 24, color: option.color),
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
                SizedBox(height: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: option.color),
              ],
            ),
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
  final Color color;

  const _MenuOption(this.text, this.icon, this.route, this.color);
}

// Placeholder screens - Reemplaza con tus implementaciones reales
// UsuariosScreen moved to lib/Screens/usuarios_screen.dart

// InformacionScreen moved to lib/Screens/informacion_screen.dart

// ContenidoScreen moved to lib/Screens/contenido_screen.dart

// PagoScreen moved to lib/Screens/pago_screen.dart

// TransaccionesScreen moved to lib/Screens/transacciones_screen.dart
