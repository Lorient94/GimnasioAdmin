// services/pricing_service.dart
class PricingService {
  static const Map<String, double> preciosClases = {
    'Yoga': 12000.00,
    'Pilates': 15000.00,
    'CrossFit': 18000.00,
    'Spinning': 13000.00,
    'Zumba': 11000.00,
    'Boxeo': 16000.00,
    'Natación': 20000.00,
    'Musculación': 10000.00,
  };

  static double obtenerPrecioClase(String nombreClase) {
    return preciosClases[nombreClase] ?? 1500.00;
  }

  static double calcularDescuento(int cantidadClases) {
    if (cantidadClases >= 10) return 0.20; // 20% descuento
    if (cantidadClases >= 5) return 0.10; // 10% descuento
    return 0.0;
  }

  static double aplicarDescuento(double precioBase, double descuento) {
    return precioBase * (1 - descuento);
  }
}
