part of 'mercado_pago_cubit.dart';

abstract class MercadoPagoState {}

class MercadoPagoInitial extends MercadoPagoState {}

class MercadoPagoLoading extends MercadoPagoState {}

class MercadoPagoLoaded extends MercadoPagoState {
  final List<Map<String, dynamic>> pagos;
  final List<Map<String, dynamic>> pagosFiltrados;

  MercadoPagoLoaded({required this.pagos, required this.pagosFiltrados});

  MercadoPagoLoaded copyWith({
    List<Map<String, dynamic>>? pagos,
    List<Map<String, dynamic>>? pagosFiltrados,
  }) {
    return MercadoPagoLoaded(
      pagos: pagos ?? this.pagos,
      pagosFiltrados: pagosFiltrados ?? this.pagosFiltrados,
    );
  }
}

class MercadoPagoError extends MercadoPagoState {
  final String message;
  MercadoPagoError({required this.message});
}
