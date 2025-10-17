import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// Importaciones de screens
import 'screens/clase_screen.dart';
import 'screens/inscripciones_screen.dart';
import 'screens/usuarios_screen.dart';
import 'screens/informacion_screen.dart';
import 'screens/contenido_screen.dart';
import 'screens/pago_screen.dart';
import 'screens/transacciones_screen.dart';

// Importaciones de repositorios
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = Dio();
    final baseUrl = 'http://127.0.0.1:8000';

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

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ClaseCubit(repository: claseRepository)),
        BlocProvider(
            create: (_) => InscripcionCubit(repository: inscripcionRepository)),
        BlocProvider(
            create: (_) => ContenidoCubit(repository: contenidoRepository)
              ..cargarContenidos()),
        BlocProvider(
            create: (_) => InformacionCubit(repository: informacionRepository)),
        BlocProvider(create: (_) => MercadoPagoCubit(mercadoPagoRepository)),
        BlocProvider(
            create: (_) => UsuarioCubit(repository: usuarioRepository)),
        BlocProvider(
            create: (_) => TransaccionCubit(repository: transaccionRepository)),
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
      ),
    );
  }

  static ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF1A73E8),
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
          .copyWith(secondary: const Color(0xFF34A853)),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A73E8),
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF1A73E8),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1A73E8),
        secondary: Color(0xFF34A853),
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

  const HomeScreen({
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Gestión - Gimnasio ABC'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A73E8).withOpacity(0.1),
              const Color(0xFF34A853).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSectionTitle(),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.25,
                          child: Image.asset(
                            'assets/images/fondo_gimnasio.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      _buildOptionsGrid(context),
                    ],
                  ),
                ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 176, 225, 244),
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
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF1A73E8),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.fitness_center, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gimnasio ABC',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sistema Integral de Gestión',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        'Módulos del Sistema',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 255, 253, 253),
        ),
      ),
    );
  }

  Widget _buildOptionsGrid(BuildContext context) {
    final options = [
      _MenuOption('Usuario', Icons.person,
          () => _navigateToScreen(context, UsuariosScreen()), Colors.blue),
      _MenuOption('Clases', Icons.fitness_center,
          () => _navigateToScreen(context, ClaseScreen()), Colors.green),
      _MenuOption(
          'Inscripciones',
          Icons.assignment,
          () => _navigateToScreen(context, InscripcionesScreen()),
          Colors.orange),
      _MenuOption('Información', Icons.info,
          () => _navigateToScreen(context, InformacionScreen()), Colors.purple),
      _MenuOption(
          'Contenido',
          Icons.video_library,
          () => _navigateToScreen(context, const ContenidoScreen()),
          Colors.red),
      _MenuOption('Pagos', Icons.payment,
          () => _navigateToScreen(context, PagoScreen()), Colors.teal),
      _MenuOption(
          'Transacciones',
          Icons.history,
          () => _navigateToScreen(context, TransaccionesScreen()),
          Colors.indigo),
    ];

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildSquareButton(options[0]),
              const SizedBox(width: 8),
              _buildSquareButton(options[1]),
              const SizedBox(width: 8),
              _buildSquareButton(options[2]),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              _buildSquareButton(options[3]),
              const SizedBox(width: 8),
              _buildSquareButton(options[4]),
              const SizedBox(width: 8),
              _buildSquareButton(options[5]),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // tercera fila: Transacciones con mismo ancho que los otros botones
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 3 - 16,
                child: _buildSquareButton(options[6], useExpanded: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSquareButton(_MenuOption option, {bool useExpanded = true}) {
    final button = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: option.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(option.icon, size: 24, color: option.color),
              ),
              const SizedBox(height: 8),
              Text(
                option.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 255, 253, 253),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    return useExpanded ? Expanded(child: button) : button;
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Text(
            '© 2025 Gimnasio ABC',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _MenuOption {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MenuOption(this.text, this.icon, this.onTap, this.color);
}
