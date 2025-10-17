part of 'mercado_pago_cubit.dart';

abstract class MercadoPagoState extends Equatable {
  const MercadoPagoState();

  @override
  List<Object?> get props => [];
}

class MercadoPagoInitial extends MercadoPagoState {
  const MercadoPagoInitial();
}

class MercadoPagoLoading extends MercadoPagoState {
  const MercadoPagoLoading();
}

class MercadoPagoLoaded extends MercadoPagoState {
  final List<Map<String, dynamic>> pagos;
  final List<Map<String, dynamic>> pagosFiltrados;

  const MercadoPagoLoaded({
    required this.pagos,
    required this.pagosFiltrados,
  });

  MercadoPagoLoaded copyWith({
    List<Map<String, dynamic>>? pagos,
    List<Map<String, dynamic>>? pagosFiltrados,
  }) {
    return MercadoPagoLoaded(
      pagos: pagos ?? this.pagos,
      pagosFiltrados: pagosFiltrados ?? this.pagosFiltrados,
    );
  }

  @override
  List<Object?> get props => [pagos, pagosFiltrados];
}

class MercadoPagoError extends MercadoPagoState {
  final String message;
  const MercadoPagoError(this.message);

  @override
  List<Object?> get props => [message];
}
