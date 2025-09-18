import 'auth_integration_test.dart' as auth_test;
import 'classes_integration_test.dart' as classes_test;
import 'profile_integration_test.dart' as profile_test;

void main() {
  auth_test.main();
  classes_test.main();
  profile_test.main();
  print('✅ Todos los tests de integración completados');
}
