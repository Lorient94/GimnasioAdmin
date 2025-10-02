import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/repositorio_api/informacion_repositorio.dart';

part 'informacion_state.dart';

class InformacionCubit extends Cubit<InformacionState> {
  final InformacionRepository _repository;

  InformacionCubit({required InformacionRepository repository})
      : _repository = repository,
        super(InformacionInitial());

  Future<void> cargarInformaciones({
    bool? soloActivas,
    String? tipo,
    int? destinatarioId,
    bool? incluirExpiradas,
  }) async {
    try {
      emit(InformacionLoading());
      final lista = await _repository.obtenerTodasLasInformaciones(
        soloActivas: soloActivas,
        tipo: tipo,
        destinatarioId: destinatarioId,
        incluirExpiradas: incluirExpiradas,
      );

      // CORRECCIÓN: Convertir explícitamente a List<Map<String, dynamic>>
      final contenidos =
          lista.map((item) => item as Map<String, dynamic>).toList();
      emit(InformacionLoaded(informaciones: contenidos, filtradas: contenidos));
    } catch (e) {
      emit(InformacionError(message: e.toString()));
    }
  }

  void filtrarLocalmente(String query) {
    if (state is! InformacionLoaded) return;
    final current = state as InformacionLoaded;
    if (query.isEmpty) {
      emit(current.copyWith(filtradas: current.informaciones));
      return;
    }

    final filtradas = current.informaciones.where((i) {
      final titulo = i['titulo']?.toString().toLowerCase() ?? '';
      final contenido = i['contenido']?.toString().toLowerCase() ?? '';
      final cuerpo = i['cuerpo']?.toString().toLowerCase() ?? '';
      return titulo.contains(query.toLowerCase()) ||
          contenido.contains(query.toLowerCase()) ||
          cuerpo.contains(query.toLowerCase());
    }).toList();

    emit(current.copyWith(filtradas: filtradas));
  }

  Future<void> crearInformacion(Map<String, dynamic> datos) async {
    try {
      if (state is! InformacionLoaded) emit(InformacionLoading());
      final nuevo = await _repository.crearInformacion(datos);
      if (state is InformacionLoaded) {
        final current = state as InformacionLoaded;
        final nuevos = [
          ...current.informaciones,
          nuevo as Map<String, dynamic> // CORRECCIÓN: Cast explícito
        ];
        emit(current.copyWith(informaciones: nuevos, filtradas: nuevos));
      } else {
        await cargarInformaciones();
      }
    } catch (e) {
      emit(InformacionError(message: e.toString()));
    }
  }

  Future<void> actualizarInformacion(int id, Map<String, dynamic> datos) async {
    try {
      emit(InformacionLoading());
      await _repository.actualizarInformacion(id, datos);
      await cargarInformaciones();
    } catch (e) {
      emit(InformacionError(message: e.toString()));
    }
  }

  Future<void> activarInformacion(int id) async {
    try {
      await _repository.activarInformacion(id);
      await cargarInformaciones();
    } catch (e) {
      emit(InformacionError(message: e.toString()));
    }
  }

  Future<void> desactivarInformacion(int id) async {
    try {
      await _repository.desactivarInformacion(id);
      await cargarInformaciones();
    } catch (e) {
      emit(InformacionError(message: e.toString()));
    }
  }

  Future<void> eliminarInformacion(int id) async {
    try {
      await _repository.eliminarInformacion(id);
      await cargarInformaciones();
    } catch (e) {
      emit(InformacionError(message: e.toString()));
    }
  }

  Future<List<dynamic>> buscarAvanzada({
    String? palabraClave,
    String? tipo,
    int? destinatarioId,
    bool? activa,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    return await _repository.buscarInformacionesAvanzada(
      palabraClave: palabraClave,
      tipo: tipo,
      destinatarioId: destinatarioId,
      activa: activa,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  void filtrarPorTipo(String tipo, String query) {
    if (state is InformacionLoaded) {
      final currentState = state as InformacionLoaded;

      List<Map<String, dynamic>> filtradas =
          currentState.informaciones.where((informacion) {
        final tipoInformacion =
            informacion['tipo']?.toString().toLowerCase() ?? '';
        final coincideTipo =
            tipo == 'todos' || tipoInformacion == tipo.toLowerCase();

        // Si no coincide el tipo, excluir
        if (!coincideTipo) return false;

        // Si hay query, aplicar búsqueda también
        if (query.isNotEmpty) {
          final titulo = informacion['titulo']?.toString().toLowerCase() ?? '';
          final contenido =
              informacion['contenido']?.toString().toLowerCase() ?? '';
          final cuerpo = informacion['cuerpo']?.toString().toLowerCase() ?? '';
          return titulo.contains(query.toLowerCase()) ||
              contenido.contains(query.toLowerCase()) ||
              cuerpo.contains(query.toLowerCase());
        }

        return true;
      }).toList();

      emit(currentState.copyWith(filtradas: filtradas));
    }
  }

  // Método adicional para limpiar filtros
  void limpiarFiltros() {
    if (state is InformacionLoaded) {
      final currentState = state as InformacionLoaded;
      emit(currentState.copyWith(filtradas: currentState.informaciones));
    }
  }
}
