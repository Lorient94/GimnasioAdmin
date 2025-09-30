part of 'transaccion_cubit.dart';

abstract class TransaccionState {}

class TransaccionInitial extends TransaccionState {}

class TransaccionLoading extends TransaccionState {}

class TransaccionLoaded extends TransaccionState {
  final List<Map<String, dynamic>> transacciones;
  final List<Map<String, dynamic>> transaccionesFiltradas;

  TransaccionLoaded(
      {required this.transacciones, required this.transaccionesFiltradas});

  TransaccionLoaded copyWith({
    List<Map<String, dynamic>>? transacciones,
    List<Map<String, dynamic>>? transaccionesFiltradas,
  }) {
    return TransaccionLoaded(
      transacciones: transacciones ?? this.transacciones,
      transaccionesFiltradas:
          transaccionesFiltradas ?? this.transaccionesFiltradas,
    );
  }
}

class TransaccionError extends TransaccionState {
  final String message;
  TransaccionError({required this.message});
}
