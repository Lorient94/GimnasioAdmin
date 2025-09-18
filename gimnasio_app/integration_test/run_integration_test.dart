import 'auth_integration_test.dart' as auth_test;
import 'classes_integration_test.dart' as classes_test;
import 'profile_integration_test.dart' as profile_test;
import 'navigation_integration_test.dart'
    as navigation_test; // ✅ Añadir este import

void main() {
  // Ejecutar todos los tests de integración
  auth_test.main();
  classes_test.main();
  profile_test.main();
  navigation_test.main(); // ✅ Ejecutar el test de navegación

  print('✅ Todos los tests de integración completados');
}
