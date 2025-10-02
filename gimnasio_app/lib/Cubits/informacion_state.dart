part of 'informacion_cubit.dart';

abstract class InformacionState {
  const InformacionState();
}

class InformacionInitial extends InformacionState {}

class InformacionLoading extends InformacionState {}

class InformacionLoaded extends InformacionState {
  final List<Map<String, dynamic>> informaciones;
  final List<Map<String, dynamic>> filtradas;

  const InformacionLoaded({
    required this.informaciones,
    required this.filtradas,
  });

  InformacionLoaded copyWith({
    List<Map<String, dynamic>>? informaciones,
    List<Map<String, dynamic>>? filtradas,
  }) {
    return InformacionLoaded(
      informaciones: informaciones ?? this.informaciones,
      filtradas: filtradas ?? this.filtradas,
    );
  }
}

class InformacionError extends InformacionState {
  final String message;

  const InformacionError({required this.message});
}
