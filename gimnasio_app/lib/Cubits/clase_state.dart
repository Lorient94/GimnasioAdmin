// cubits/clase_state.dart
part of 'clase_cubit.dart';

abstract class ClaseState {
  const ClaseState();
}

class ClaseInitial extends ClaseState {}

class ClaseLoading extends ClaseState {}

class ClaseError extends ClaseState {
  final String message;
  const ClaseError({required this.message});
}

class ClaseLoaded extends ClaseState {
  final List<Map<String, dynamic>> clases;
  final List<Map<String, dynamic>> clasesFiltradas;

  const ClaseLoaded({
    required this.clases,
    required this.clasesFiltradas,
  });

  ClaseLoaded copyWith({
    List<Map<String, dynamic>>? clases,
    List<Map<String, dynamic>>? clasesFiltradas,
  }) {
    return ClaseLoaded(
      clases: clases ?? this.clases,
      clasesFiltradas: clasesFiltradas ?? this.clasesFiltradas,
    );
  }
}
