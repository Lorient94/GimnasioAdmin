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
        debugShowCheckedModeBanner: false,
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
        home: const HomeScreen(),
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
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Gestión - Gimnasio ABC'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A73E8).withOpacity(0.9),
                const Color(0xFF34A853).withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_gimnasio.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildCompactHeader(),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildVeryCompactOptionsGrid(context),
                ),
                _buildCompactFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A73E8), Color(0xFF34A853)],
              ),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.fitness_center, size: 50, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gimnasio ABC',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                Text(
                  'Sistema de Gestión',
                  style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeryCompactOptionsGrid(BuildContext context) {
    final options = [
      _MenuOption(
        'Usuarios',
        Icons.people_alt,
        () => _navigateToScreen(context, const UsuariosScreen()),
        const Color(0xFF3F51B5),
      ),
      _MenuOption(
        'Clases',
        Icons.fitness_center,
        () => _navigateToScreen(context, ClaseScreen()),
        const Color(0xFF3F51B5),
      ),
      _MenuOption(
        'Inscripciones',
        Icons.assignment,
        () => _navigateToScreen(context, InscripcionesScreen()),
        const Color(0xFF3F51B5),
      ),
      _MenuOption(
        'Información',
        Icons.info,
        () => _navigateToScreen(context, InformacionScreen()),
        const Color(0xFF3F51B5),
      ),
      _MenuOption(
        'Contenido',
        Icons.video_library,
        () => _navigateToScreen(context, const ContenidoScreen()),
        const Color(0xFF3F51B5),
      ),
      _MenuOption(
        'Pagos',
        Icons.payment,
        () => _navigateToScreen(context, const PagoScreen()),
        const Color(0xFF3F51B5),
      ),
      _MenuOption(
        'Transacciones',
        Icons.receipt_long,
        () => _navigateToScreen(context, TransaccionesScreen()),
        const Color(0xFF3F51B5),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columnas
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 2.9, // 🔹 Más ancho y menos alto
      ),
      padding: const EdgeInsets.all(0),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return _buildMinimalButton(options[index]);
      },
    );
  }

  Widget _buildMinimalButton(_MenuOption option) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3F51B5), // Azul principal (predomina)
              Color(0xFF3F51B5), // Mantiene azul en casi todo
              Color.fromARGB(255, 38, 125, 61), // Verde leve al final
            ],
            stops: [0.0, 0.6, 3.0], // 🔹 80% azul, 20% verde
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: option.onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(option.icon, size: 60, color: Colors.white),
                  const SizedBox(height: 2),
                  Text(
                    option.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFooter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          '© 2025 Gimnasio ABC',
          style: TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ),
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
