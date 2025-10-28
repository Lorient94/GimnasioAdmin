// repositories/mercado_pago_repository.dart - VERSIÓN ACTUALIZADA
import 'package:dio/dio.dart';

class MercadoPagoRepository {
  final Dio dio;
  final String baseUrl;

  MercadoPagoRepository({required this.dio, required this.baseUrl});

  // ==================== ENDPOINTS PRINCIPALES ====================

  /// Obtener historial de pagos - USANDO ENDPOINT CORRECTO
  Future<List<dynamic>> obtenerHistorialPagos({
    String? clienteDni,
    String? estado,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (clienteDni != null) params['cliente_dni'] = clienteDni;
      if (estado != null) params['estado'] = estado;

      final response = await dio.get(
        '$baseUrl/api/mercado-pago/pagos',
        queryParameters: params,
      );

      // El endpoint devuelve { "modo": "SIMULADO", "total_pagos": X, "pagos": [...] }
      final data = response.data;
      if (data is Map && data.containsKey('pagos')) {
        return data['pagos'];
      }
      return List<dynamic>.from(data);
    } on DioException catch (e) {
      throw Exception(
          'Error obteniendo historial de pagos: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Error obteniendo historial de pagos: $e');
    }
  }

  /// Obtener pagos de un usuario específico
  Future<List<dynamic>> obtenerPagosUsuario(String usuarioDni) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/mercado-pago/pagos',
        queryParameters: {'cliente_dni': usuarioDni},
      );

      final data = response.data;
      if (data is Map && data.containsKey('pagos')) {
        return data['pagos'];
      }
      return List<dynamic>.from(data);
    } on DioException catch (e) {
      throw Exception(
          'Error obteniendo pagos del usuario: ${e.response?.data ?? e.message}');
    }
  }

  // ==================== CREAR PAGO ====================
  Future<Map<String, dynamic>> crearPago(Map<String, dynamic> pagoData) async {
    try {
      // Adaptar datos para el nuevo endpoint
      final datosAdaptados = {
        "cliente_dni": pagoData["id_usuario"],
        "monto": pagoData["monto"],
        "concepto": pagoData["concepto"],
        "cliente_nombre": pagoData["cliente_nombre"] ?? "Cliente",
        "cliente_email": pagoData["cliente_email"] ?? "cliente@email.com",
        "metodo_pago": pagoData["metodo_pago"] ?? "mercado_pago",
      };

      final response = await dio.post(
        '$baseUrl/api/mercado-pago/crear-pago-prueba',
        data: datosAdaptados,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear pago: ${e.response?.data ?? e.message}');
    }
  }

  // ==================== CREAR PREFERENCIA ====================
  Future<Map<String, dynamic>> crearPreferenciaPago(
      Map<String, dynamic> preferenciaData) async {
    try {
      // Usar el mismo endpoint que crearPago pero adaptado
      final datosAdaptados = {
        "cliente_dni": preferenciaData["id_usuario"],
        "monto": preferenciaData["monto"],
        "concepto": preferenciaData["concepto"],
        "cliente_nombre": preferenciaData["cliente_nombre"] ?? "Cliente",
        "cliente_email":
            preferenciaData["cliente_email"] ?? "cliente@email.com",
      };

      final response = await dio.post(
        '$baseUrl/api/mercado-pago/crear-pago-prueba',
        data: datosAdaptados,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al crear preferencia de pago: ${e.response?.data ?? e.message}');
    }
  }

  // ==================== VERIFICAR PAGO ====================
  Future<Map<String, dynamic>> verificarPago(int pagoId) async {
    try {
      // Por ahora, en modo simulado, devolvemos éxito
      return {
        "status": "approved",
        "modo": "simulado",
        "message": "Pago verificado en modo simulado"
      };
    } on DioException catch (e) {
      throw Exception(
          'Error al verificar pago: ${e.response?.data ?? e.message}');
    }
  }

  // ==================== REEMBOLSAR PAGO ====================
  Future<Map<String, dynamic>> reembolsarPago({
    required int pagoId,
    double? monto,
  }) async {
    try {
      // En modo simulado, simulamos reembolso
      return {
        "success": true,
        "modo": "simulado",
        "message": "Reembolso simulado exitosamente"
      };
    } on DioException catch (e) {
      throw Exception(
          'Error al reembolsar pago: ${e.response?.data ?? e.message}');
    }
  }

  // ==================== MÉTODOS NUEVOS PARA PRUEBAS ====================

  /// Crear pago de prueba
  Future<Map<String, dynamic>> crearPagoPrueba(
      Map<String, dynamic> pagoData) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/mercado-pago/crear-pago-prueba',
        data: pagoData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al crear pago prueba: ${e.response?.data ?? e.message}');
    }
  }

  /// Simular pago exitoso
  Future<Map<String, dynamic>> simularPagoExitoso(String preferenceId) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/mercado-pago/simular-pago-exitoso/$preferenceId',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al simular pago: ${e.response?.data ?? e.message}');
    }
  }

  /// Obtener tarjetas de prueba
  Future<Map<String, dynamic>> obtenerTarjetasPrueba() async {
    try {
      final response = await dio.get(
        '$baseUrl/api/mercado-pago/tarjetas-prueba',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error obteniendo tarjetas: ${e.response?.data ?? e.message}');
    }
  }

  // ==================== MÉTODOS ADICIONALES ====================

  Future<Map<String, dynamic>> actualizarPago(
      int pagoId, Map<String, dynamic> datos) async {
    try {
      // Por ahora no tenemos endpoint de actualización, simulamos
      return {
        "success": true,
        "modo": "simulado",
        "message": "Pago actualizado simulado"
      };
    } on DioException catch (e) {
      throw Exception(
          'Error al actualizar pago: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> obtenerDetallePago(int pagoId) async {
    try {
      // Buscar en la lista de pagos
      final response = await dio.get('$baseUrl/api/mercado-pago/pagos');
      final data = response.data;
      List<dynamic> pagos = [];

      if (data is Map && data.containsKey('pagos')) {
        pagos = data['pagos'];
      } else {
        pagos = List<dynamic>.from(data);
      }

      final pago = pagos.firstWhere((p) => p['id'] == pagoId,
          orElse: () => throw Exception('Pago no encontrado'));

      return pago;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener detalle del pago: ${e.response?.data ?? e.message}');
    }
  }

  /// Obtener transacciones con pagos
  Future<List<dynamic>> obtenerTransaccionesConPagos(
      {String? clienteDni}) async {
    try {
      final Map<String, dynamic> params = {};
      if (clienteDni != null) params['cliente_dni'] = clienteDni;

      final response = await dio.get(
        '$baseUrl/api/mercado-pago/transacciones-con-pagos',
        queryParameters: params,
      );

      final data = response.data;
      if (data is Map && data.containsKey('transacciones')) {
        return data['transacciones'];
      }
      return List<dynamic>.from(data);
    } on DioException catch (e) {
      throw Exception(
          'Error obteniendo transacciones: ${e.response?.data ?? e.message}');
    }
  }

  /// Crear pago con transacción
  Future<Map<String, dynamic>> crearPagoConTransaccion(
      Map<String, dynamic> pagoData) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/mercado-pago/crear-pago-prueba',
        data: pagoData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear pago: ${e.response?.data ?? e.message}');
    }
  }
}
