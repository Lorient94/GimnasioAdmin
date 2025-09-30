import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/repositorio_api/usuario_repositorio.dart';

part 'usuario_state.dart';

class UsuarioCubit extends Cubit<UsuarioState> {
  final UsuarioRepository _repository;

  UsuarioCubit({required UsuarioRepository repository})
      : _repository = repository,
        super(UsuarioInitial());

  Future<void> cargarUsuarios(
      {bool? soloActivos, String? filtroNombre, String? filtroDni}) async {
    try {
      emit(UsuarioLoading());
      final lista = await _repository.obtenerTodosLosUsuarios(
          soloActivos: soloActivos,
          filtroNombre: filtroNombre,
          filtroDni: filtroDni);
      final usuarios = List<Map<String, dynamic>>.from(lista);
      emit(UsuarioLoaded(usuarios: usuarios, usuariosFiltrados: usuarios));
    } catch (e) {
      emit(UsuarioError(message: e.toString()));
    }
  }

  Future<Map<String, dynamic>> obtenerDetalle(int id) async {
    try {
      final res = await _repository.obtenerDetalleUsuario(id);
      return res;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> crearUsuario(Map<String, dynamic> datos) async {
    try {
      emit(UsuarioLoading());
      final res = await _repository.crearUsuario(datos);
      if (state is UsuarioLoaded) {
        final current = state as UsuarioLoaded;
        final nuevos = [...current.usuarios, Map<String, dynamic>.from(res)];
        emit(current.copyWith(usuarios: nuevos, usuariosFiltrados: nuevos));
      } else {
        await cargarUsuarios();
      }
    } catch (e) {
      emit(UsuarioError(message: e.toString()));
    }
  }

  Future<void> actualizarUsuario(int id, Map<String, dynamic> datos) async {
    try {
      emit(UsuarioLoading());
      await _repository.actualizarUsuario(id, datos);
      await cargarUsuarios();
    } catch (e) {
      emit(UsuarioError(message: e.toString()));
    }
  }

  Future<void> activarUsuario(int id) async {
    try {
      emit(UsuarioLoading());
      await _repository.activarUsuario(id);
      await cargarUsuarios();
    } catch (e) {
      emit(UsuarioError(message: e.toString()));
    }
  }

  Future<void> desactivarUsuario(int id) async {
    try {
      emit(UsuarioLoading());
      await _repository.desactivarUsuario(id);
      await cargarUsuarios();
    } catch (e) {
      emit(UsuarioError(message: e.toString()));
    }
  }

  Future<void> eliminarUsuario(int id) async {
    try {
      emit(UsuarioLoading());
      await _repository.eliminarUsuario(id);
      await cargarUsuarios();
    } catch (e) {
      emit(UsuarioError(message: e.toString()));
    }
  }

  /// Filtra los usuarios cargados en memoria por nombre o DNI.
  /// Si el query está vacío, restaura la lista completa.
  void filtrarUsuarios(String query) {
    final q = query.trim().toLowerCase();
    if (state is UsuarioLoaded) {
      final current = state as UsuarioLoaded;
      if (q.isEmpty) {
        emit(current.copyWith(usuariosFiltrados: current.usuarios));
        return;
      }
      final filtrados = current.usuarios.where((u) {
        final nombre = (u['nombre'] ?? '').toString().toLowerCase();
        final dni = (u['dni'] ?? '').toString().toLowerCase();
        return nombre.contains(q) || dni.contains(q);
      }).toList();
      emit(current.copyWith(usuariosFiltrados: filtrados));
    }
  }
}
