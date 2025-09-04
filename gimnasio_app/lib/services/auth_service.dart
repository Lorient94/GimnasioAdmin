// services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userData['id']); // Guardar ID
    await prefs.setString('user_dni', userData['dni']);
    await prefs.setString('user_nombre', userData['nombre']);
    await prefs.setString('user_correo', userData['correo']);
    await prefs.setBool('is_logged_in', true);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id'); // Obtener ID
    final dni = prefs.getString('user_dni');
    final nombre = prefs.getString('user_nombre');
    final correo = prefs.getString('user_correo');

    if (id != null && dni != null && nombre != null && correo != null) {
      return {
        'id': id, // Incluir ID
        'dni': dni,
        'nombre': nombre,
        'correo': correo,
      };
    }
    return null;
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id'); // Método para obtener solo el ID
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_dni');
    await prefs.remove('user_nombre');
    await prefs.remove('user_correo');
    await prefs.remove('is_logged_in');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
}
