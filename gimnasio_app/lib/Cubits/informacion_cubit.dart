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

      final contenidos = List<Map<String, dynamic>>.from(lista);
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
      final cuerpo = i['cuerpo']?.toString().toLowerCase() ?? '';
      return titulo.contains(query.toLowerCase()) ||
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
          Map<String, dynamic>.from(nuevo)
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
}
