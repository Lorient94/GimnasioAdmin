// repositories/contenido_repository.dart
import 'package:dio/dio.dart';

class ContenidoRepository {
  final Dio dio;
  final String baseUrl;

  ContenidoRepository({required this.dio, required this.baseUrl});

  // ==================== OBTENER CONTENIDO ====================
  Future<List<dynamic>> obtenerTodoElContenido({
    bool? soloActivos,
    String? categoria,
    String? tipoArchivo,
    String? palabraClave,
  }) async {
    try {
      print('🔍 ContenidoRepository: Obteniendo contenido...');
      print('🌐 URL: $baseUrl/api/admin/contenidos/');

      final response = await dio.get(
        '$baseUrl/api/admin/contenidos/',
        queryParameters: {
          if (soloActivos != null) 'solo_activos': soloActivos,
          if (categoria != null) 'categoria': categoria,
          if (tipoArchivo != null) 'tipo_archivo': tipoArchivo,
          if (palabraClave != null) 'palabra_clave': palabraClave,
        },
      );

      print(
          '✅ ContenidoRepository: Response recibida - ${response.statusCode}');
      print('📦 Datos: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      print('❌ ContenidoRepository Error: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw Exception('Error al obtener contenido: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleContenido(int contenidoId) async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/contenidos/$contenidoId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al obtener detalle contenido: ${e.response?.data}');
    }
  }

  // ==================== GESTIÓN DE CONTENIDO ====================
  Future<Map<String, dynamic>> crearContenido(
      Map<String, dynamic> datosContenido) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/admin/contenidos/',
        data: datosContenido,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear contenido: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> crearContenidoConArchivo({
    required String titulo,
    required String descripcion,
    required String categoria,
    required MultipartFile archivo,
    bool esPublico = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'titulo': titulo,
        'descripcion': descripcion,
        'categoria': categoria,
        'archivo': archivo,
        'es_publico': esPublico,
      });

      final response = await dio.post(
        '$baseUrl/api/admin/contenidos/con-archivo',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al crear contenido con archivo: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> actualizarContenido(
      int contenidoId, Map<String, dynamic> datos) async {
    try {
      final response = await dio.put(
        '$baseUrl/api/admin/contenidos/$contenidoId',
        data: datos,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al actualizar contenido: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> activarContenido(int contenidoId) async {
    try {
      final response =
          await dio.patch('$baseUrl/api/admin/contenidos/$contenidoId/activar');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al activar contenido: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> desactivarContenido(int contenidoId) async {
    try {
      final response =
          await dio.delete('$baseUrl/api/admin/contenidos/$contenidoId');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al desactivar contenido: ${e.response?.data}');
    }
  }

  // ==================== CATEGORÍAS ====================
  Future<List<String>> obtenerCategoriasDisponibles() async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/contenidos/categorias/disponibles');
      return response.data['categorias'] ?? [];
    } on DioException catch (e) {
      throw Exception('Error al obtener categorías: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> crearCategoria(String categoria) async {
    try {
      final response =
          await dio.post('$baseUrl/api/admin/contenidos/categorias/$categoria');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al crear categoría: ${e.response?.data}');
    }
  }

  // ==================== REPORTES ====================
  Future<List<dynamic>> generarReporteCategorias() async {
    try {
      final response =
          await dio.get('$baseUrl/api/admin/contenidos/reporte/categorias');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          'Error al generar reporte categorías: ${e.response?.data}');
    }
  }

  Future<Map<String, dynamic>> generarReporteTiposContenido() async {
    try {
      final response = await dio
          .get('$baseUrl/api/admin/contenidos/reporte/tipos-contenido');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error al generar reporte tipos: ${e.response?.data}');
    }
  }
}
