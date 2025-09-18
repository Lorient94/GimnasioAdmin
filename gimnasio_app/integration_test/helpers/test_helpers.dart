import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_app/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

class IntegrationTestConfig {
  static Future<void> initializeApp(WidgetTester tester) async {
    // Configurar SharedPreferences mock ANTES de iniciar la app
    SharedPreferences.setMockInitialValues({});

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  static Future<void> clearPreferences() async {
    // Usar el mock en lugar de la instancia real
    SharedPreferences.setMockInitialValues({});
  }

  static Future<void> loginUser(WidgetTester tester) async {
    // Implementación de login...
  }
}

extension WidgetTesterExtensions on WidgetTester {
  Future<void> tapAndWait(String text,
      {Duration duration = const Duration(milliseconds: 500)}) async {
    await tap(find.text(text));
    await pumpAndSettle(duration);
  }

  Future<void> enterTextAndWait(Finder finder, String text,
      {Duration duration = const Duration(milliseconds: 500)}) async {
    await enterText(finder, text);
    await pumpAndSettle(duration);
  }
}
