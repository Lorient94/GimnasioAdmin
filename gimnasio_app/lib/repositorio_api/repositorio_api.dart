// repositorio_api/repositorio_api.dart
import 'package:dio/dio.dart';
import '../services/network_service.dart';

class RepositorioAPI {
  String baseUrl;
  final Dio _dio;

  RepositorioAPI({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 REQUEST: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('❌ ERROR: ${e.type}');
        return handler.next(e);
      },
    ));
  }

  // Método para cambiar la URL dinámicamente
  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    print('🔄 URL actualizada: $baseUrl');
  }

  Future<Map<String, dynamic>> testConnection() async {
    return await NetworkService.testConnection(baseUrl);
  }

  // Método estático para crear instancia con IP automática
  static Future<RepositorioAPI> createWithAutoIP() async {
    final serverIp = await NetworkService.findServerIp();
    if (serverIp != null) {
      return RepositorioAPI(baseUrl: 'http://$serverIp:8000');
    } else {
      throw Exception('No se pudo encontrar el servidor automáticamente');
    }
  }

  // CLIENTES
  Future<List<dynamic>> obtenerClientes() async {
    final response = await _dio.get('$baseUrl/api/clientes/');
    return response.data;
  }

  Future<dynamic> crearCliente(Map<String, dynamic> datosCliente) async {
    try {
      print('🌐 POST $baseUrl/api/clientes/ con: $datosCliente');
      final response = await _dio.post(
        '$baseUrl/api/clientes/',
        data: datosCliente,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
        ),
      );
      print(
          '✅ Respuesta Dio: ${response.data}, statusCode: ${response.statusCode}');
      return response.data;
    } on DioException catch (e, stackTrace) {
      print('❌ ERROR en crearCliente: $e');
      print('Response data: ${e.response?.data}');
      print('Response status: ${e.response?.statusCode}');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<int> obtenerIdDesdeDni(String dni) async {
    try {
      final clientes = await obtenerClientes();
      final cliente = clientes.firstWhere((c) => c['dni'] == dni,
          orElse: () => throw Exception('Cliente no encontrado'));
      return cliente['id'];
    } catch (e) {
      throw Exception('Error obteniendo ID desde DNI: $e');
    }
  }

  Future<dynamic> loginCliente(String correo, String password) async {
    final response = await _dio.post('$baseUrl/api/clientes/login', data: {
      'correo': correo,
      'password': password,
    });
    return response.data;
  }

  Future<bool> autenticarCorreo(String correo) async {
    final response =
        await _dio.get('$baseUrl/api/clientes/verificar-correo/$correo');
    if (response.statusCode == 200) {
      return response.data['existe'] == true;
    }
    return false;
  }

  Future<Response> actualizarCliente(int id, Map<String, dynamic> datos) async {
    return await _dio.put('$baseUrl/api/clientes/$id', data: datos);
  }

  // CLASES
  Future<List<dynamic>> obtenerClases(
      {String? instructor, String? horario}) async {
    final response = await _dio.get(
      '$baseUrl/api/clases',
      queryParameters: {
        if (instructor != null) 'instructor': instructor,
        if (horario != null) 'horario': horario,
      },
    );
    return response.data;
  }

  Future<dynamic> crearClase(Map<String, dynamic> datosClase) async {
    final response = await _dio.post('$baseUrl/api/clases', data: datosClase);
    return response.data;
  }

  Future<List<dynamic>> buscarClasesPorInstructor(String instructor) async {
    final response =
        await _dio.get('$baseUrl/api/clases/instructor/$instructor');
    return response.data;
  }

  Future<List<dynamic>> buscarClasesPorDificultad(String nivel) async {
    final response = await _dio.get('$baseUrl/api/clases/dificultad/$nivel');
    return response.data;
  }

  Future<List<dynamic>> buscarClasesPorHorario(String horario) async {
    final response = await _dio.get('$baseUrl/api/clases/horario/$horario');
    return response.data;
  }

  // INSCRIPCIONES
  Future<List<dynamic>> obtenerInscripciones(
      {String? clienteDni, int? claseId}) async {
    final response =
        await _dio.get('$baseUrl/api/inscripciones', queryParameters: {
      if (clienteDni != null) 'cliente_dni': clienteDni,
      if (claseId != null) 'clase_id': claseId,
    });
    return response.data;
  }

  Future<dynamic> crearInscripcion(
      Map<String, dynamic> datosInscripcion) async {
    final response =
        await _dio.post('$baseUrl/api/inscripciones/', data: datosInscripcion);
    return response.data;
  }

  Future<dynamic> cancelarInscripcion(int inscripcionId, String motivo) async {
    final response = await _dio.patch(
      '$baseUrl/api/inscripciones/$inscripcionId/cancelar',
      data: {'motivo': motivo},
    );
    return response.data;
  }

  // CONTENIDOS
  Future<List<dynamic>> obtenerContenidos({String? categoria}) async {
    final response =
        await _dio.get('$baseUrl/api/contenidos', queryParameters: {
      if (categoria != null) 'categoria': categoria,
    });
    return response.data;
  }

  Future<dynamic> crearContenido(Map<String, dynamic> datosContenido) async {
    final response =
        await _dio.post('$baseUrl/api/contenidos', data: datosContenido);
    return response.data;
  }

  Future<List<dynamic>> buscarContenidosPorPalabra(String palabra) async {
    final response = await _dio.get('$baseUrl/api/contenidos/buscar/$palabra');
    return response.data;
  }

  Future<List<dynamic>> buscarContenidosPorFecha(String fecha) async {
    final response = await _dio.get('$baseUrl/api/contenidos/fecha/$fecha');
    return response.data;
  }

  Future<dynamic> descargarContenido(int contenidoId) async {
    final response = await _dio.get(
      '$baseUrl/api/contenidos/$contenidoId/descargar',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  // INFORMACIONES
  Future<List<dynamic>> obtenerInformaciones(
      {String? tipo, int? destinatarioId}) async {
    final response =
        await _dio.get('$baseUrl/api/informaciones', queryParameters: {
      if (tipo != null) 'tipo': tipo,
      if (destinatarioId != null) 'destinatario_id': destinatarioId,
    });
    return response.data;
  }

  Future<dynamic> crearInformacion(
      Map<String, dynamic> datosInformacion) async {
    final response =
        await _dio.post('$baseUrl/api/informaciones', data: datosInformacion);
    return response.data;
  }

  Future<List<dynamic>> buscarInformacionesPorPalabra(String palabra) async {
    final response =
        await _dio.get('$baseUrl/api/informaciones/buscar/$palabra');
    return response.data;
  }

  Future<List<dynamic>> buscarInformacionesPorFecha(String fecha) async {
    final response = await _dio.get('$baseUrl/api/informaciones/fecha/$fecha');
    return response.data;
  }

  // TRANSACCIONES
  Future<List<dynamic>> obtenerTransacciones(
      {String? clienteDni, String? estado}) async {
    final response =
        await _dio.get('$baseUrl/api/transacciones', queryParameters: {
      if (clienteDni != null) 'cliente_dni': clienteDni,
      if (estado != null) 'estado': estado,
    });
    return response.data;
  }

  Future<dynamic> crearTransaccion(
      Map<String, dynamic> datosTransaccion) async {
    final response =
        await _dio.post('$baseUrl/api/transacciones', data: datosTransaccion);
    return response.data;
  }

  // PAGOS
  Future<List<dynamic>> obtenerPagos(
      {String? usuarioDni, int? transaccionId}) async {
    final response = await _dio.get('$baseUrl/api/pago', queryParameters: {
      if (usuarioDni != null) 'id_usuario': usuarioDni,
      if (transaccionId != null) 'transaccion_id': transaccionId,
    });
    return response.data;
  }

  Future<dynamic> crearPago(Map<String, dynamic> datosPago) async {
    final response = await _dio.post('$baseUrl/api/pago', data: datosPago);
    return response.data;
  }
}
