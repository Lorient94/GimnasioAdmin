// repositories/mercado_pago_repository.dart
import 'package:dio/dio.dart';

class MercadoPagoRepository {
  final Dio dio;
  final String baseUrl;

  MercadoPagoRepository({required this.dio, required this.baseUrl});

  // ==================== CREAR PAGO ====================
  Future<Map<String, dynamic>> crearPago(Map<String, dynamic> pagoData) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/mercado-pago/crear-pago',
        data: pagoData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear pago: ${e.response?.data}');
    }
  }

  // ==================== VERIFICAR PAGO ====================
  Future<Map<String, dynamic>> verificarPago(int pagoId) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/mercado-pago/verificar-pago/$pagoId',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al verificar pago: ${e.response?.data}');
    }
  }

  // ==================== PROCESAR WEBHOOK ====================
  Future<Map<String, dynamic>> procesarWebhook(
      Map<String, dynamic> webhookData) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/mercado-pago/webhook',
        data: webhookData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al procesar webhook: ${e.response?.data}');
    }
  }

  // ==================== REEMBOLSAR PAGO ====================
  Future<Map<String, dynamic>> reembolsarPago({
    required int pagoId,
    double? monto,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/mercado-pago/reembolsar/$pagoId',
        queryParameters: {
          if (monto != null) 'monto': monto,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al reembolsar pago: ${e.response?.data}');
    }
  }

  // ==================== PAGOS ADICIONALES (si los necesitas) ====================

  // Obtener historial de pagos con filtros opcionales
  Future<List<dynamic>> obtenerHistorialPagos({
    String? estado,
    String? clienteDni,
    String? fechaInicio,
    String? fechaFin,
    int? limite,
    int? offset,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/pagos', // Asumiendo que tienes este endpoint
        queryParameters: {
          if (estado != null) 'estado': estado,
          if (clienteDni != null) 'cliente_dni': clienteDni,
          if (fechaInicio != null) 'fecha_inicio': fechaInicio,
          if (fechaFin != null) 'fecha_fin': fechaFin,
          if (limite != null) 'limite': limite,
          if (offset != null) 'offset': offset,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener historial de pagos: ${e.response?.data}');
    }
  }

  // Obtener detalle de un pago específico
  Future<Map<String, dynamic>> obtenerDetallePago(int pagoId) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/pagos/$pagoId', // Asumiendo que tienes este endpoint
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener detalle del pago: ${e.response?.data}');
    }
  }

  // ==================== ACTUALIZAR PAGO ====================
  Future<Map<String, dynamic>> actualizarPago(
      int pagoId, Map<String, dynamic> datos) async {
    try {
      final response = await dio.put(
        '$baseUrl/api/pagos/$pagoId',
        data: datos,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al actualizar pago: ${e.response?.data}');
    }
  }

  // ==================== MÉTODOS PARA PREFERENCIAS DE PAGO ====================
  Future<Map<String, dynamic>> crearPreferenciaPago(
      Map<String, dynamic> preferenciaData) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/mercado-pago/crear-preferencia', // Si tienes este endpoint
        data: preferenciaData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al crear preferencia de pago: ${e.response?.data}');
    }
  }

  // ==================== MÉTODOS PARA GESTIÓN DE REEMBOLSOS ====================
  Future<List<dynamic>> obtenerReembolsosPago(int pagoId) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/mercado-pago/reembolsos/$pagoId', // Si tienes este endpoint
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener reembolsos del pago: ${e.response?.data}');
    }
  }

  // ==================== MÉTODOS PARA ESTADÍSTICAS ====================
  Future<Map<String, dynamic>> obtenerEstadisticasPagos({
    String? periodo,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/mercado-pago/estadisticas', // Si tienes este endpoint
        queryParameters: {
          if (periodo != null) 'periodo': periodo,
          if (fechaInicio != null) 'fecha_inicio': fechaInicio,
          if (fechaFin != null) 'fecha_fin': fechaFin,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener estadísticas de pagos: ${e.response?.data}');
    }
  }
}
