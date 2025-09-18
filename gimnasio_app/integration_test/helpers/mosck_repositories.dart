import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:gimnasio_app/repositorio_api/repositorio_api.dart';

// Genera los mocks con: flutter pub run build_runner build
@GenerateMocks([RepositorioAPI])
void main() {}

// Mock manual para pruebas básicas
class MockRepositorioAPI extends Mock implements RepositorioAPI {
  @override
  Future<Map<String, dynamic>> loginCliente(
      String email, String password) async {
    if (email == 'test@example.com' && password == 'password123') {
      return {
        'id': 1,
        'dni': '12345678',
        'nombre': 'Usuario Test',
        'correo': 'test@example.com'
      };
    }
    throw Exception('Credenciales inválidas');
  }

  @override
  Future<bool> autenticarCorreo(String email) async {
    return email == 'test@example.com';
  }

  @override
  Future<Map<String, dynamic>> testConnection() async {
    return {'connected': true};
  }
}
