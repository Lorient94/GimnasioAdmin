import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_app/main.dart';
import 'package:gimnasio_app/Screens/inicioSesion.dart';
import 'package:gimnasio_app/Screens/registroUsuario.dart';
import 'package:gimnasio_app/Screens/verClases.dart';
import 'package:gimnasio_app/Screens/verContenido.dart';
import 'package:gimnasio_app/Screens/verInformacion.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';

void main() {
  // Creamos un mock simple de RepositorioAPI para los tests
  final mockApi = RepositorioAPI(baseUrl: 'http://localhost:3000');

  testWidgets('El menú principal muestra todas las opciones',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    expect(find.text('Bienvenido al Gimnasio ABC'), findsOneWidget);
    expect(find.text('Crear Usuario'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Editar Perfil'), findsOneWidget);
    expect(find.text('Ver Clases'), findsOneWidget);
    expect(find.text('Ver Contenido'), findsOneWidget);
    expect(find.text('Información'), findsOneWidget);
    expect(find.text('Administrar Inscripciones'), findsOneWidget);
    expect(find.text('Cronograma de Clases'), findsOneWidget);
  });

  testWidgets('Navega a RegistroUsuarioScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    await tester.ensureVisible(find.text('Crear Usuario'));
    await tester.tap(find.text('Crear Usuario'));
    await tester.pumpAndSettle();
    expect(find.byType(RegistroUsuarioScreen), findsOneWidget);
  });

  testWidgets('Navega a InicioSesionScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    await tester.ensureVisible(find.text('Iniciar Sesión'));
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(InicioSesionScreen), findsOneWidget);
  });

  testWidgets('Navega a EditarPerfilScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    await tester.ensureVisible(find.text('Editar Perfil'));
    await tester.tap(find.text('Editar Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Editar Perfil'), findsOneWidget);
  });

  testWidgets('Navega a VerClasesScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    await tester.ensureVisible(find.text('Ver Clases'));
    await tester.tap(find.text('Ver Clases'));
    await tester.pumpAndSettle();
    expect(find.byType(VerClasesScreen), findsOneWidget);
  });

  testWidgets('Navega a VerContenidoScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    await tester.ensureVisible(find.text('Ver Contenido'));
    await tester.tap(find.text('Ver Contenido'));
    await tester.pumpAndSettle();
    expect(find.byType(VerContenidoScreen), findsOneWidget);
  });

  testWidgets('Navega a VerInformacionScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    await tester.ensureVisible(find.text('Información'));
    await tester.tap(find.text('Información'));
    await tester.pumpAndSettle();
    expect(find.byType(VerInformacionScreen), findsOneWidget);
  });

  testWidgets('Navega a AdministrarInscripcionesScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    await tester.ensureVisible(find.text('Administrar Inscripciones'));
    await tester.tap(find.text('Administrar Inscripciones'));
    await tester.pumpAndSettle();
    expect(find.text('Administrar Inscripciones'), findsOneWidget);
  });

  testWidgets('Navega a CronogramaClasesScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: mockApi));
    await tester.ensureVisible(find.text('Cronograma de Clases'));
    await tester.tap(find.text('Cronograma de Clases'));
    await tester.pumpAndSettle();
    expect(find.text('Cronograma de Clases'), findsOneWidget);
  });
}
