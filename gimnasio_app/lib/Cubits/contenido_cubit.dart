import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/repositorio_api/contenido_repositorio.dart';

part 'contenido_state.dart';

class ContenidoCubit extends Cubit<ContenidoState> {
  final ContenidoRepository _repository;

  ContenidoCubit({required ContenidoRepository repository})
      : _repository = repository,
        super(ContenidoInitial());

  Future<void> cargarContenidos({
    bool? soloActivos,
    String? categoria,
    String? tipoArchivo,
    String? palabraClave,
  }) async {
    try {
      emit(ContenidoLoading());
      final lista = await _repository.obtenerTodoElContenido(
        soloActivos: soloActivos,
        categoria: categoria,
        tipoArchivo: tipoArchivo,
        palabraClave: palabraClave,
      );
      final contenidosTyped = List<Map<String, dynamic>>.from(lista);

      // Obtener categorías disponibles (no bloqueante)
      List<String> categorias = [];
      try {
        categorias = await _repository.obtenerCategoriasDisponibles();
      } catch (_) {
        categorias = [];
      }

      emit(ContenidoLoaded(
        contenidos: contenidosTyped,
        contenidosFiltrados: contenidosTyped,
        categorias: categorias,
      ));
    } catch (e) {
      emit(ContenidoError(message: e.toString()));
    }
  }

  void filtrarContenidos({String? titulo, String? categoria}) {
    if (state is! ContenidoLoaded) return;
    final current = state as ContenidoLoaded;
    List<Map<String, dynamic>> filtrados = current.contenidos;

    if (titulo != null && titulo.isNotEmpty) {
      filtrados = filtrados
          .where((c) => c['titulo']
              .toString()
              .toLowerCase()
              .contains(titulo.toLowerCase()))
          .toList();
    }

    if (categoria != null && categoria.isNotEmpty && categoria != 'todas') {
      filtrados = filtrados
          .where((c) => c['categoria']?.toString() == categoria)
          .toList();
    }

    emit(current.copyWith(contenidosFiltrados: filtrados));
  }

  Future<void> crearContenido(Map<String, dynamic> datos) async {
    try {
      if (state is! ContenidoLoaded) emit(ContenidoLoading());
      final nuevo = await _repository.crearContenido(datos);

      if (state is ContenidoLoaded) {
        final current = state as ContenidoLoaded;
        final nuevos = [
          ...current.contenidos,
          Map<String, dynamic>.from(nuevo)
        ];
        emit(current.copyWith(contenidos: nuevos, contenidosFiltrados: nuevos));
      } else {
        await cargarContenidos();
      }
    } catch (e) {
      emit(ContenidoError(message: e.toString()));
    }
  }

  Future<void> actualizarContenido(int id, Map<String, dynamic> datos) async {
    try {
      emit(ContenidoLoading());
      await _repository.actualizarContenido(id, datos);
      await cargarContenidos();
    } catch (e) {
      emit(ContenidoError(message: e.toString()));
    }
  }

  Future<void> activarContenido(int id) async {
    try {
      await _repository.activarContenido(id);
      await cargarContenidos();
    } catch (e) {
      emit(ContenidoError(message: e.toString()));
    }
  }

  Future<void> desactivarContenido(int id) async {
    try {
      await _repository.desactivarContenido(id);
      await cargarContenidos();
    } catch (e) {
      emit(ContenidoError(message: e.toString()));
    }
  }

  Future<List<dynamic>> generarReporteCategorias() async {
    try {
      return await _repository.generarReporteCategorias();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> generarReporteTiposContenido() async {
    try {
      return await _repository.generarReporteTiposContenido();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
