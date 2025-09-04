// services/network_service.dart
import 'package:dio/dio.dart';

class NetworkService {
  static final List<String> commonSubnets = [
    '192.168.1', // Redes comunes
    '192.168.0',
    '192.168.43', // Hotspot común
    '10.0.0',
    '10.0.2', // Emulador Android
  ];

  static final List<int> commonPorts = [8000, 3000, 8080, 5000];

  static Future<String?> findServerIp() async {
    print('🔍 Buscando servidor...');

    // Probar IPs comunes primero
    final commonIps = [
      '192.168.1.1', '192.168.1.16', '192.168.1.100', '192.168.1.50',
      '192.168.0.1', '192.168.0.100', '192.168.0.50',
      '192.168.43.1', // Hotspot
      '10.0.2.2', // Emulador
    ];

    for (final ip in commonIps) {
      for (final port in commonPorts) {
        final found = await _testConnection(ip, port);
        if (found != null) return found;
      }
    }

    // Escanear subredes si las comunes fallan
    for (final subnet in commonSubnets) {
      print('🔍 Escaneando subnet: $subnet.XXX');
      for (int i = 1; i <= 255; i++) {
        final ip = '$subnet.$i';
        for (final port in commonPorts) {
          final found = await _testConnection(ip, port);
          if (found != null) return found;
        }
      }
    }

    return null;
  }

  static Future<String?> _testConnection(String ip, int port) async {
    final url = 'http://$ip:$port/health';
    try {
      final dio = Dio(BaseOptions(connectTimeout: Duration(milliseconds: 500)));
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        print('✅ Servidor encontrado en: $ip:$port');
        return ip;
      }
    } catch (e) {
      // Silenciar errores, solo queremos encontrar la IP correcta
    }
    return null;
  }

  static Future<Map<String, dynamic>> testConnection(String baseUrl) async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: Duration(seconds: 3)));
      final response = await dio.get('$baseUrl/health');
      return {
        'connected': true,
        'data': response.data,
        'statusCode': response.statusCode
      };
    } on DioException catch (e) {
      return {
        'connected': false,
        'error': e.message,
        'type': e.type.toString(),
        'statusCode': e.response?.statusCode
      };
    }
  }
}
