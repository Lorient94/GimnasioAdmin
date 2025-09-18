import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_helpers.dart';

void main() {
  group('Flujo de Navegación - Integration Test', () {
    setUp(() async {
      // Configurar usuario logueado
      await IntegrationTestConfig.clearPreferences();
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_id': 1,
        'user_dni': '12345678',
        'user_nombre': 'Usuario Test',
        'user_correo': 'test@example.com'
      });
    });

    testWidgets('Navegación entre tabs después de login',
        (WidgetTester tester) async {
      // Arrange
      await IntegrationTestConfig.initializeApp(tester);

      // Assert - Verificar que estamos en el main navigation
      expect(find.text('Hola, Usuario Test'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Navegación a pantalla de información',
        (WidgetTester tester) async {
      // Arrange
      await IntegrationTestConfig.initializeApp(tester);

      // Primero volver al home si estamos en navigation
      if (find.text('Hola, Usuario Test').evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.logout).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Act - Navegar a información
      await tester.tapAndWait('Información');

      // Assert
      expect(find.text('Información del Gimnasio'), findsOneWidget);
    });
  });
}
