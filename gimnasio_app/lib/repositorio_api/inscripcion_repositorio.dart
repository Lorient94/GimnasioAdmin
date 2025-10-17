// repositories/inscripcion_repository.dart
import 'package:dio/dio.dart';

class InscripcionRepository {
  final Dio dio;
  final String baseUrl;

  InscripcionRepository({required this.dio, required this.baseUrl});

  // ==================== OBTENER INSCRIPCIONES ====================
  Future<List<dynamic>> obtenerTodasLasInscripciones({
    String? estado,
    String? clienteDni,
    int? claseId,
    bool? soloActivas,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/inscripciones',
        queryParameters: {
          if (estado != null) 'estado': estado,
          if (clienteDni != null) 'cliente_dni': clienteDni,
          if (claseId != null) 'clase_id': claseId,
          if (soloActivas != null) 'solo_activas': soloActivas,
          if (fechaInicio != null) 'fecha_inicio': fechaInicio,
          if (fechaFin != null) 'fecha_fin': fechaFin,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener inscripciones: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleInscripcion(
      int inscripcionId) async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/inscripciones/$inscripcionId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener detalle inscripción: ${e.response?.data}');
    }
  }

  // ==================== GESTIÓN DE INSCRIPCIONES ====================
  Future<Map<String, dynamic>> crearInscripcion(
      Map<String, dynamic> datosInscripcion) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/admin/inscripciones',
        data: datosInscripcion,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear inscripción: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> cancelarInscripcion(
      int inscripcionId, String motivo) async {
    try {
      final response = await dio.patch(
        '$baseUrl/api/admin/inscripciones/$inscripcionId/cancelar',
        data: {'motivo': motivo},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al cancelar inscripción: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> reactivarInscripcion(int inscripcionId) async {
    try {
      final response = await dio
          .patch('$baseUrl/api/admin/inscripciones/$inscripcionId/reactivar');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al reactivar inscripción: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> completarInscripcion(int inscripcionId) async {
    try {
      final response = await dio
          .patch('$baseUrl/api/admin/inscripciones/$inscripcionId/completar');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al completar inscripción: ${e.response?.data}');
    }
  }

  // ==================== REPORTES ====================
  Future<List<dynamic>> generarReporteClasesPopulares() async {
    try {
      final response = await dio
          .get('$baseUrl/api/admin/inscripciones/reporte/clases-populares');
      return response.data['clases_populares'] ?? [];
    } on DioException catch (e) {
      throw Exception(
          'Error al generar reporte clases populares: ${e.response?.data}');
    }
  }

  Future<List<dynamic>> generarReporteClientesActivos() async {
    try {
      final response = await dio
          .get('$baseUrl/api/admin/inscripciones/reporte/clientes-activos');
      return response.data['clientes_activos'] ?? [];
    } on DioException catch (e) {
      throw Exception(
          'Error al generar reporte clientes activos: ${e.response?.data}');
    }
  }

  // ==================== ALERTAS ====================
  Future<List<Map<String, dynamic>>> obtenerAlertasCuposCriticos(
      [int porcentajeAlerta = 80]) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/inscripciones/alertas/cupos-criticos',
        queryParameters: {'porcentaje_alerta': porcentajeAlerta},
      );

      // 🔹 Convertir explícitamente la lista de alertas
      final List<dynamic> rawAlertas = response.data['alertas'] ?? [];
      return rawAlertas.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener alertas cupos críticos: ${e.response?.data}');
    }
  }
}
