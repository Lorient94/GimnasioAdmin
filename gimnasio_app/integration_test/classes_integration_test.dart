import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_helpers.dart';

void main() {
  group('Flujo de Clases - Integration Test', () {
    setUp(() async {
      await IntegrationTestConfig.clearPreferences();
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
      expect(find.text('Hola, Usuario Test'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Navegación entre tabs funciona correctamente',
        (WidgetTester tester) async {
      await IntegrationTestConfig.initializeApp(tester);

      final calendarIcons = find.byIcon(Icons.calendar_today);
      await tester.tap(calendarIcons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
          find.descendant(
              of: find.byType(Scaffold),
              matching: find.textContaining(
                  RegExp('cronograma|clase', caseSensitive: false))),
          findsAtLeast(1));

      final personIcons = find.byIcon(Icons.person);
      await tester.tap(personIcons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Usuario Test'), findsAtLeast(1));
      expect(find.text('test@example.com'), findsAtLeast(1));
    });
  });
}
