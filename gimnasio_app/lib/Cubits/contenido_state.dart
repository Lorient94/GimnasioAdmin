part of 'contenido_cubit.dart';

abstract class ContenidoState {}

class ContenidoInitial extends ContenidoState {}

class ContenidoLoading extends ContenidoState {}

class ContenidoLoaded extends ContenidoState {
  final List<Map<String, dynamic>> contenidos;
  final List<Map<String, dynamic>> contenidosFiltrados;
  final List<String> categorias;

  ContenidoLoaded({
    required this.contenidos,
    required this.contenidosFiltrados,
    required this.categorias,
  });

  ContenidoLoaded copyWith({
    List<Map<String, dynamic>>? contenidos,
    List<Map<String, dynamic>>? contenidosFiltrados,
    List<String>? categorias,
  }) {
    return ContenidoLoaded(
      contenidos: contenidos ?? this.contenidos,
      contenidosFiltrados: contenidosFiltrados ?? this.contenidosFiltrados,
      categorias: categorias ?? this.categorias,
    );
  }
}

class ContenidoError extends ContenidoState {
  final String message;
  ContenidoError({required this.message});
}
