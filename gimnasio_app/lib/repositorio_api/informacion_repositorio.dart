// repositories/informacion_repository.dart
import 'package:dio/dio.dart';

class InformacionRepository {
  final Dio dio;
  final String baseUrl;

  InformacionRepository({required this.dio, required this.baseUrl});

  // ==================== OBTENER INFORMACIONES ====================
  Future<List<dynamic>> obtenerTodasLasInformaciones({
    bool? soloActivas,
    String? tipo,
    int? destinatarioId,
    bool? incluirExpiradas,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/informaciones',
        queryParameters: {
          if (soloActivas != null) 'solo_activas': soloActivas,
          if (tipo != null) 'tipo': tipo,
          if (destinatarioId != null) 'destinatario_id': destinatarioId,
          if (incluirExpiradas != null) 'incluir_expiradas': incluirExpiradas,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener informaciones: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleInformacion(
      int informacionId) async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/informaciones/$informacionId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener detalle información: ${e.response?.data}');
    }
  }

  Future<List<dynamic>> obtenerInformacionesCliente(String clienteDni) async {
    try {
      final response = await dio
          .get('$baseUrl/api/admin/informaciones/cliente/$clienteDni/completo');
      return response.data['informaciones'] ?? [];
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener informaciones cliente: ${e.response?.data}');
    }
  }

  // ==================== GESTIÓN DE INFORMACIONES ====================
  Future<Map<String, dynamic>> crearInformacion(
      Map<String, dynamic> datosInformacion) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/admin/informaciones',
        data: datosInformacion,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear información: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> actualizarInformacion(
      int informacionId, Map<String, dynamic> datos) async {
    try {
      final response = await dio.put(
        '$baseUrl/api/admin/informaciones/$informacionId',
        data: datos,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al actualizar información: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> activarInformacion(int informacionId) async {
    try {
      final response = await dio
          .patch('$baseUrl/api/admin/informaciones/$informacionId/activar');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al activar información: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> desactivarInformacion(int informacionId) async {
    try {
      final response = await dio
          .patch('$baseUrl/api/admin/informaciones/$informacionId/desactivar');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al desactivar información: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> eliminarInformacion(int informacionId) async {
    try {
      final response =
          await dio.delete('$baseUrl/api/admin/informaciones/$informacionId');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al eliminar información: ${e.response?.data}');
    }
  }

  // ==================== BÚSQUEDA ====================
  Future<List<dynamic>> buscarInformacionesAvanzada({
    String? palabraClave,
    String? tipo,
    int? destinatarioId,
    bool? activa,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/informaciones/buscar/avanzada',
        queryParameters: {
          if (palabraClave != null) 'palabra_clave': palabraClave,
          if (tipo != null) 'tipo': tipo,
          if (destinatarioId != null) 'destinatario_id': destinatarioId,
          if (activa != null) 'activa': activa,
          if (fechaInicio != null) 'fecha_inicio': fechaInicio,
          if (fechaFin != null) 'fecha_fin': fechaFin,
        },
      );
      return response.data['resultados'] ?? [];
    } on DioException catch (e) {
      throw Exception('Error en búsqueda avanzada: ${e.response?.data}');
    }
  }

  // ==================== REPORTES ====================
  Future<Map<String, dynamic>> generarReportePorTipo() async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/informaciones/reporte/tipos');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al generar reporte por tipo: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> generarReporteTemporal(
      String fechaInicio, String fechaFin) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/informaciones/reporte/temporal',
        queryParameters: {
          'fecha_inicio': fechaInicio,
          'fecha_fin': fechaFin,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al generar reporte temporal: ${e.response?.data}');
    }
  }

  // ==================== ALERTAS ====================
  Future<List<dynamic>> obtenerAlertasExpiracionProxima(
      [int diasAntes = 7]) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/informaciones/alertas/expiracion-proxima',
        queryParameters: {'dias_antes': diasAntes},
      );
      return response.data['alertas'] ?? [];
    } on DioException catch (e) {
      throw Exception('Error al obtener alertas: ${e.response?.data}');
    }
  }
}
