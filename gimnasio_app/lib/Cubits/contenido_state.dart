// cubits/contenido_state.dart
part of 'contenido_cubit.dart';

abstract class ContenidoState {
  const ContenidoState();
}

class ContenidoInitial extends ContenidoState {}

class ContenidoLoading extends ContenidoState {}

class ContenidoLoaded extends ContenidoState {
  final List<Map<String, dynamic>> contenidos;
  final List<Map<String, dynamic>> filtradas;
  final List<String> categorias;

  const ContenidoLoaded({
    required this.contenidos,
    required this.filtradas,
    required this.categorias,
  });

  ContenidoLoaded copyWith({
    List<Map<String, dynamic>>? contenidos,
    List<Map<String, dynamic>>? filtradas,
    List<String>? categorias,
  }) {
    return ContenidoLoaded(
      contenidos: contenidos ?? this.contenidos,
      filtradas: filtradas ?? this.filtradas,
      categorias: categorias ?? this.categorias,
    );
  }
}

class ContenidoError extends ContenidoState {
  final String message;

  const ContenidoError({required this.message});
}
