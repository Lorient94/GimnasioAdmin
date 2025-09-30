import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gimnasio_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App arranca y muestra Home', (WidgetTester tester) async {
    // Nota: MyApp requiere repositorios en su constructor en main.dart.
    // Para integración real, habría que crear instancias de repositorios con Dio
    // apuntando a backend de pruebas o usar mocks via un punto de inyección.

    // Aquí dejamos un esqueleto que solo arranca la app si se adapta el constructor.
    // app.main();

    // await tester.pumpAndSettle();
    // expect(find.textContaining('Gimnasio ABC'), findsOneWidget);
  });
}
