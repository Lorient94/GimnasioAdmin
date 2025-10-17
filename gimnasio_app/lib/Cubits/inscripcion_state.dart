part of 'inscripcion_cubit.dart';

abstract class InscripcionState extends Equatable {
  const InscripcionState();

  @override
  List<Object> get props => [];
}

class InscripcionInitial extends InscripcionState {}

class InscripcionLoading extends InscripcionState {}

class InscripcionLoaded extends InscripcionState {
  final List<dynamic> inscripciones;
  final List<dynamic> inscripcionesFiltradas;

  const InscripcionLoaded({
    required this.inscripciones,
    required this.inscripcionesFiltradas,
  });

  InscripcionLoaded copyWith({
    List<dynamic>? inscripciones,
    List<dynamic>? inscripcionesFiltradas,
  }) {
    return InscripcionLoaded(
      inscripciones: inscripciones ?? this.inscripciones,
      inscripcionesFiltradas:
          inscripcionesFiltradas ?? this.inscripcionesFiltradas,
    );
  }

  @override
  List<Object> get props => [inscripciones, inscripcionesFiltradas];
}

class InscripcionAlertasLoaded extends InscripcionState {
  final List<Map<String, dynamic>> alertas;

  const InscripcionAlertasLoaded({required this.alertas});

  @override
  List<Object> get props => [alertas];
}

class InscripcionError extends InscripcionState {
  final String error;
  final List<dynamic> inscripciones;

  const InscripcionError({
    required this.error,
    this.inscripciones = const [],
  });

  @override
  List<Object> get props => [error, ...inscripciones];
}
