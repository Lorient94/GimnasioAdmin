part of 'informacion_cubit.dart';

abstract class InformacionState {}

class InformacionInitial extends InformacionState {}

class InformacionLoading extends InformacionState {}

class InformacionLoaded extends InformacionState {
  final List<Map<String, dynamic>> informaciones;
  final List<Map<String, dynamic>> filtradas;

  InformacionLoaded({required this.informaciones, required this.filtradas});

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
  InformacionError({required this.message});
}
