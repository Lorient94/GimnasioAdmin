// repositories/transaccion_repository.dart
import 'package:dio/dio.dart';

class TransaccionRepository {
  final Dio dio;
  final String baseUrl;

  TransaccionRepository({required this.dio, required this.baseUrl});

  // ==================== OBTENER TRANSACCIONES ====================
  Future<List<dynamic>> obtenerTodasLasTransacciones({
    String? estado,
    String? clienteDni,
    String? metodoPago,
    String? fechaInicio,
    String? fechaFin,
    double? montoMinimo,
    double? montoMaximo,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones',
        queryParameters: {
          if (estado != null) 'estado': estado,
          if (clienteDni != null) 'cliente_dni': clienteDni,
          if (metodoPago != null) 'metodo_pago': metodoPago,
          if (fechaInicio != null) 'fecha_inicio': fechaInicio,
          if (fechaFin != null) 'fecha_fin': fechaFin,
          if (montoMinimo != null) 'monto_minimo': montoMinimo,
          if (montoMaximo != null) 'monto_maximo': montoMaximo,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al obtener transacciones: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleTransaccion(
      int transaccionId) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/$transaccionId',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener detalle de transacción: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerTransaccionPorReferencia(
      String referencia) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/referencia/$referencia/completo',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener transacción por referencia: ${e.response?.data}');
    }
  }

  // ==================== GESTIÓN DE TRANSACCIONES ====================
  Future<Map<String, dynamic>> crearTransaccion(
      Map<String, dynamic> datosTransaccion) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/admin/transacciones',
        data: datosTransaccion,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear transacción: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> actualizarTransaccion(
    int transaccionId,
    Map<String, dynamic> datosActualizacion,
  ) async {
    try {
      final response = await dio.put(
        '$baseUrl/api/admin/transacciones/$transaccionId',
        data: datosActualizacion,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al actualizar transacción: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> cambiarEstadoTransaccion(
    int transaccionId,
    String estado,
    String? observaciones,
  ) async {
    try {
      final response = await dio.patch(
        '$baseUrl/api/admin/transacciones/$transaccionId/estado',
        data: {
          'estado': estado,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al cambiar estado de transacción: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> marcarComoPagada(
    int transaccionId, {
    String? referenciaPago,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/api/admin/transacciones/$transaccionId/marcar-como-pagada',
        queryParameters: {
          if (referenciaPago != null) 'referencia_pago': referenciaPago,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al marcar transacción como pagada: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> revertirTransaccion(
    int transaccionId,
    String motivo,
  ) async {
    try {
      final response = await dio.patch(
        '$baseUrl/api/admin/transacciones/$transaccionId/revertir',
        queryParameters: {'motivo': motivo},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al revertir transacción: ${e.response?.data}');
    }
  }

  // ==================== ELIMINACIÓN DE TRANSACCIONES ====================
  Future<Map<String, dynamic>> eliminarTransaccion(int transaccionId) async {
    try {
      final response = await dio.delete(
        '$baseUrl/api/admin/transacciones/$transaccionId',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al eliminar transacción: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> eliminarTransaccionesMasivas(
      List<int> transaccionIds) async {
    try {
      final response = await dio.delete(
        '$baseUrl/api/admin/transacciones/batch/eliminar',
        queryParameters: {'transaccion_ids': transaccionIds},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al eliminar transacciones masivas: ${e.response?.data}');
    }
  }

  // ==================== ESTADÍSTICAS Y REPORTES ====================
  Future<Map<String, dynamic>> obtenerEstadisticasAvanzadas() async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/estadisticas/avanzadas',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener estadísticas avanzadas: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> generarReporteDiario(String fecha) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/reporte/diario',
        queryParameters: {'fecha': fecha},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al generar reporte diario: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> generarReporteMensual(int anio, int mes) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/reporte/mensual',
        queryParameters: {'año': anio, 'mes': mes},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al generar reporte mensual: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> generarReporteMetodosPagoDetallado({
    required String fechaInicio,
    required String fechaFin,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/reporte/metodos-pago/detallado',
        queryParameters: {
          'fecha_inicio': fechaInicio,
          'fecha_fin': fechaFin,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al generar reporte métodos de pago: ${e.response?.data}');
    }
  }

  // ==================== GESTIÓN DE CLIENTES ====================
  Future<Map<String, dynamic>> obtenerTransaccionesClienteCompleto(
    String clienteDni, {
    bool incluirHistoricas = true,
    int limite = 100,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/cliente/$clienteDni/completo',
        queryParameters: {
          'incluir_historicas': incluirHistoricas,
          'limite': limite,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener transacciones del cliente: ${e.response?.data}');
    }
  }

  // ==================== ALERTAS Y MONITOREO ====================
  Future<Map<String, dynamic>> obtenerAlertasTransaccionesPendientes({
    int horasLimite = 24,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/alertas/transacciones-pendientes',
        queryParameters: {'horas_limite': horasLimite},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener alertas de transacciones pendientes: ${e.response?.data}');
    }
  }

  // ==================== BÚSQUEDA AVANZADA ====================
  Future<Map<String, dynamic>> busquedaAvanzadaTransacciones({
    String? referencia,
    String? clienteDni,
    String? estado,
    String? metodoPago,
    double? montoMinimo,
    double? montoMaximo,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/buscar/avanzada',
        queryParameters: {
          if (referencia != null) 'referencia': referencia,
          if (clienteDni != null) 'cliente_dni': clienteDni,
          if (estado != null) 'estado': estado,
          if (metodoPago != null) 'metodo_pago': metodoPago,
          if (montoMinimo != null) 'monto_minimo': montoMinimo,
          if (montoMaximo != null) 'monto_maximo': montoMaximo,
          if (fechaInicio != null) 'fecha_inicio': fechaInicio,
          if (fechaFin != null) 'fecha_fin': fechaFin,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error en búsqueda avanzada: ${e.response?.data}');
    }
  }

  // ==================== DASHBOARD ====================
  Future<Map<String, dynamic>> obtenerDashboardEstadisticas() async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/dashboard/estadisticas',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener estadísticas del dashboard: ${e.response?.data}');
    }
  }

  // ==================== MÉTODOS ADICIONALES ÚTILES ====================
  Future<List<dynamic>> obtenerUltimasTransacciones({int limite = 10}) async {
    try {
      final todas = await obtenerTodasLasTransacciones();
      return todas.take(limite).toList();
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener últimas transacciones: ${e.response?.data}');
    }
  }

  Future<List<dynamic>> obtenerTransaccionesPorEstado(String estado) async {
    try {
      return await obtenerTodasLasTransacciones(estado: estado);
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener transacciones por estado: ${e.response?.data}');
    }
  }

  Future<List<dynamic>> obtenerTransaccionesPorFecha(String fecha) async {
    try {
      return await obtenerTodasLasTransacciones(
        fechaInicio: fecha,
        fechaFin: fecha,
      );
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener transacciones por fecha: ${e.response?.data}');
    }
  }

  // ==================== MÉTODOS CONVENCIONALES PARA PARÁMETROS ====================
  Future<Map<String, dynamic>> generarReporteMensualConParametros({
    required int anio,
    required int mes,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/admin/transacciones/reporte/mensual',
        queryParameters: {'año': anio, 'mes': mes},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al generar reporte mensual: ${e.response?.data}');
    }
  }
}
