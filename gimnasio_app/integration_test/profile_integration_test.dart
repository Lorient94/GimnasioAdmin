import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_helpers.dart';

void main() {
  group('Flujo de Perfil - Integration Test', () {
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

    testWidgets('Datos de usuario se muestran correctamente en UI',
        (WidgetTester tester) async {
      await IntegrationTestConfig.initializeApp(tester);
      expect(find.text('Hola, Usuario Test'), findsOneWidget);

      final personIcons = find.byIcon(Icons.person);
      await tester.tap(personIcons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Usuario Test'), findsAtLeast(1));
      expect(find.text('test@example.com'), findsAtLeast(1));
    });

    testWidgets('Logout funciona correctamente', (WidgetTester tester) async {
      await IntegrationTestConfig.initializeApp(tester);

      final logoutButtons = find.byIcon(Icons.logout);
      await tester.tap(logoutButtons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Bienvenido al Gimnasio ABC'), findsOneWidget);
      expect(find.text('Hola,'), findsNothing);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });
  });
}
