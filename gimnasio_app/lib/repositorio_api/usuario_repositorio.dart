// repositories/usuario_repository.dart
import 'package:dio/dio.dart';

class UsuarioRepository {
  final Dio dio;
  final String baseUrl;

  UsuarioRepository({required this.dio, required this.baseUrl});

  // ==================== OBTENER USUARIOS ====================
  Future<List<dynamic>> obtenerTodosLosUsuarios({
    bool? soloActivos,
    String? filtroNombre,
    String? filtroDni,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/clientes',
        queryParameters: {
          if (soloActivos != null) 'solo_activos': soloActivos,
          if (filtroNombre != null) 'nombre': filtroNombre,
          if (filtroDni != null) 'dni': filtroDni,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener usuarios: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleUsuario(int usuarioId) async {
    try {
      final response = await dio.get('$baseUrl/api/admin/clientes/$usuarioId');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener detalle usuario: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerUsuarioPorDni(String dni) async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/clientes/dni/$dni/completo');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener usuario por DNI: ${e.response?.data}');
    }
  }

  // ==================== GESTIÓN DE USUARIOS ====================
  Future<Map<String, dynamic>> crearUsuario(
      Map<String, dynamic> datosUsuario) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/admin/clientes',
        data: datosUsuario,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear usuario: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> actualizarUsuario(
      int usuarioId, Map<String, dynamic> datos) async {
    try {
      final response = await dio.put(
        '$baseUrl/api/admin/clientes/$usuarioId',
        data: datos,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al actualizar usuario: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> activarUsuario(int usuarioId) async {
    try {
      final response =
          await dio.patch('$baseUrl/api/admin/clientes/$usuarioId/activar');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al activar usuario: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> desactivarUsuario(int usuarioId) async {
    try {
      final response =
          await dio.patch('$baseUrl/api/admin/clientes/$usuarioId/desactivar');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al desactivar usuario: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> eliminarUsuario(int usuarioId) async {
    try {
      final response =
          await dio.delete('$baseUrl/api/admin/clientes/$usuarioId');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al eliminar usuario: ${e.response?.data}');
    }
  }

  // ==================== ESTADÍSTICAS ====================
  Future<Map<String, dynamic>> obtenerEstadisticasUsuarios() async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/clientes/estadisticas/totales');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerDashboardUsuarios() async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/clientes/dashboard/estadisticas');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener dashboard: ${e.response?.data}');
    }
  }
}
