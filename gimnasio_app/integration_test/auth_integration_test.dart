import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gimnasio_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo de Autenticación - Integration Test', () {
    testWidgets('App inicia correctamente en pantalla de home',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Buscamos el texto de bienvenida usando Key o texto exacto
      expect(find.byKey(Key('homeWelcomeText')), findsOneWidget);
      expect(find.text('Bienvenido al Gimnasio ABC'), findsOneWidget);
    });

    testWidgets('Navegación a pantalla de login', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap al botón de login usando Key
      final loginButton = find.byKey(Key('homeLoginButton'));
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verificamos que aparezca la pantalla de login
      expect(find.byKey(Key('loginTitle')), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });

    testWidgets('Navegación a pantalla de registro',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final registerButton = find.byKey(Key('homeRegisterButton'));
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.byKey(Key('registerTitle')), findsOneWidget);
      expect(find.text('Crear Usuario'), findsOneWidget);
    });

    testWidgets('Login con credenciales inválidas muestra error',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final loginButton = find.byKey(Key('homeLoginButton'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Ingresar email y contraseña
      await tester.enterText(
          find.byKey(Key('loginEmailField')), 'invalid@email.com');
      await tester.enterText(
          find.byKey(Key('loginPasswordField')), 'wrongpassword');

      final submitButton = find.byKey(Key('loginSubmitButton'));
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verificamos que aparezca mensaje de error
      expect(find.byKey(Key('loginErrorText')), findsOneWidget);
      expect(find.text('Credenciales inválidas'), findsOneWidget);
    });
  });
}
