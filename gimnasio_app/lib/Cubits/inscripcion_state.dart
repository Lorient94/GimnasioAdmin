// cubits/inscripcion/inscripcion_state.dart
part of 'inscripcion_cubit.dart';

abstract class InscripcionState extends Equatable {
  final List<dynamic> inscripciones;

  const InscripcionState({this.inscripciones = const []});

  @override
  List<Object> get props => [inscripciones];
}

class InscripcionInitial extends InscripcionState {
  const InscripcionInitial() : super(inscripciones: const []);
}

class InscripcionLoading extends InscripcionState {
  const InscripcionLoading() : super(inscripciones: const []);
}

class InscripcionLoaded extends InscripcionState {
  final List<dynamic> inscripcionesFiltradas;

  const InscripcionLoaded({
    required List<dynamic> inscripciones,
    required this.inscripcionesFiltradas,
  }) : super(inscripciones: inscripciones);

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

class InscripcionError extends InscripcionState {
  final String error;

  const InscripcionError({
    required this.error,
    List<dynamic> inscripciones = const [],
  }) : super(inscripciones: inscripciones);

  @override
  List<Object> get props => [error, ...super.props];
}
