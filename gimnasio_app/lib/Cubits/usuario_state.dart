part of 'usuario_cubit.dart';

abstract class UsuarioState {}

class UsuarioInitial extends UsuarioState {}

class UsuarioLoading extends UsuarioState {}

class UsuarioLoaded extends UsuarioState {
  final List<Map<String, dynamic>> usuarios;
  final List<Map<String, dynamic>> usuariosFiltrados;

  UsuarioLoaded({required this.usuarios, required this.usuariosFiltrados});

  UsuarioLoaded copyWith(
      {List<Map<String, dynamic>>? usuarios,
      List<Map<String, dynamic>>? usuariosFiltrados}) {
    return UsuarioLoaded(
      usuarios: usuarios ?? this.usuarios,
      usuariosFiltrados: usuariosFiltrados ?? this.usuariosFiltrados,
    );
  }
}

class UsuarioError extends UsuarioState {
  final String message;
  UsuarioError({required this.message});
}
