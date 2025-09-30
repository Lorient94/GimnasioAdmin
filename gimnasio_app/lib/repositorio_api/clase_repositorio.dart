// repositories/clase_repository.dart
import 'package:dio/dio.dart';

class ClaseRepository {
  final Dio dio;
  final String baseUrl;

  ClaseRepository({required this.dio, required this.baseUrl});

  // ==================== OBTENER CLASES ====================
  Future<List<dynamic>> obtenerTodasLasClases({
    bool? soloActivas,
    String? instructor,
    String? dificultad,
    String? horario,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/clases',
        queryParameters: {
          if (soloActivas != null) 'solo_activas': soloActivas,
          if (instructor != null) 'instructor': instructor,
          if (dificultad != null) 'dificultad': dificultad,
          if (horario != null) 'horario': horario,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener clases: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleClase(int claseId) async {
    try {
      final response = await dio.get('$baseUrl/api/admin/clases/$claseId');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener detalle clase: ${e.response?.data}');
    }
  }

  // ==================== GESTIÓN DE CLASES ====================
  Future<Map<String, dynamic>> crearClase(
      Map<String, dynamic> datosClase) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/admin/clases',
        data: datosClase,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear clase: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> actualizarClase(
      int claseId, Map<String, dynamic> datos) async {
    try {
      final response = await dio.put(
        '$baseUrl/api/admin/clases/$claseId',
        data: datos,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al actualizar clase: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> activarClase(int claseId) async {
    try {
      final response =
          await dio.patch('$baseUrl/api/admin/clases/$claseId/activar');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al activar clase: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> desactivarClase(int claseId) async {
    try {
      final response = await dio.delete('$baseUrl/api/admin/clases/$claseId');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al desactivar clase: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> duplicarClase(
      int claseId, String nuevoNombre) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/admin/clases/$claseId/duplicar',
        queryParameters: {'nuevo_nombre': nuevoNombre},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al duplicar clase: ${e.response?.data}');
    }
  }

  // ==================== INSCRIPCIONES ====================
  Future<List<dynamic>> obtenerInscripcionesClase(int claseId) async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/clases/$claseId/inscripciones');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener inscripciones: ${e.response?.data}');
    }
  }

  // ==================== REPORTES ====================
  Future<List<dynamic>> generarReporteOcupacion() async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/clases/reporte/ocupacion');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al generar reporte ocupación: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> generarReporteDificultad() async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/clases/reporte/dificultad');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al generar reporte dificultad: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> generarReporteInstructores() async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/clases/reporte/instructores');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al generar reporte instructores: ${e.response?.data}');
    }
  }

  // ==================== ESTADÍSTICAS ====================
  Future<Map<String, dynamic>> obtenerEstadisticasClase(int claseId) async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/clases/$claseId/estadisticas');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.response?.data}');
    }
  }
}
