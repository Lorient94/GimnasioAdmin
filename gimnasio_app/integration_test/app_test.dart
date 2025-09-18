import 'package:flutter/material.dart'; // ✅ Añadir este import
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_helpers.dart'; // ✅ Solo una importación

void main() {
  group('Flujo de Clases - Integration Test', () {
    setUp(() async {
      await IntegrationTestConfig.clearPreferences();
      // Configurar usuario logueado
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_id': 1,
        'user_dni': '12345678',
        'user_nombre': 'Usuario Test',
        'user_correo': 'test@example.com'
      });
    });

    testWidgets('Usuario logueado ve pantalla principal con tabs',
        (WidgetTester tester) async {
      await IntegrationTestConfig.initializeApp(tester);

      // Verificar que estamos en el navigation screen con usuario logueado
      expect(find.text('Hola, Usuario Test'), findsOneWidget);

      // Verificar que los tabs de navegación están presentes
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    // ✅ Eliminar la línea que causa error o crear el archivo
    // calendar_test.main(); // Comenta o elimina esta línea

    // ✅ En su lugar, añade el test directamente aquí:
    testWidgets('Navegación entre tabs funciona correctamente',
        (WidgetTester tester) async {
      await IntegrationTestConfig.initializeApp(tester);

      // Tap en el tab de calendario (segundo tab)
      final calendarIcons = find.byIcon(Icons.calendar_today);
      await tester.tap(calendarIcons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verificar que cambió la pantalla - buscar texto típico de cronograma o clases
      expect(
          find.descendant(
              of: find.byType(Scaffold),
              matching: find.textContaining(
                  RegExp('cronograma|clase', caseSensitive: false))),
          findsAtLeast(1));

      // Tap en el tab de perfil (tercer tab)
      final personIcons = find.byIcon(Icons.person);
      await tester.tap(personIcons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verificar pantalla de perfil
      expect(find.text('Usuario Test'), findsAtLeast(1));
      expect(find.text('test@example.com'), findsAtLeast(1));
    });
  });
}
