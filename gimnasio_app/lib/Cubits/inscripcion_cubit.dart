import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gimnasio_app/repositorio_api/inscripcion_repositorio.dart';

part 'inscripcion_state.dart';

class InscripcionCubit extends Cubit<InscripcionState> {
  final InscripcionRepository _repository;

  InscripcionCubit({required InscripcionRepository repository})
      : _repository = repository,
        super(InscripcionInitial());

  // ==================== CARGA DE INSCRIPCIONES ====================
  Future<void> cargarInscripciones({
    String? estado,
    String? clienteDni,
    int? claseId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    emit(InscripcionLoading());
    try {
      final inscripciones = await _repository.obtenerTodasLasInscripciones(
        estado: estado,
        clienteDni: clienteDni,
        claseId: claseId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      emit(InscripcionLoaded(
        inscripciones: inscripciones,
        inscripcionesFiltradas: inscripciones,
      ));
    } catch (e) {
      emit(InscripcionError(error: e.toString()));
    }
  }

  // ==================== FILTRADO LOCAL ====================
  void filtrarInscripciones(String query) {
    if (state is InscripcionLoaded) {
      final currentState = state as InscripcionLoaded;
      if (query.isEmpty) {
        emit(currentState.copyWith(
            inscripcionesFiltradas: currentState.inscripciones));
        return;
      }

      final inscripcionesFiltradas =
          currentState.inscripciones.where((inscripcion) {
        final nombreCliente =
            inscripcion['nombre_cliente']?.toString().toLowerCase() ?? '';
        final claseNombre =
            inscripcion['clase_nombre']?.toString().toLowerCase() ?? '';
        final estado = inscripcion['estado']?.toString().toLowerCase() ?? '';
        return nombreCliente.contains(query.toLowerCase()) ||
            claseNombre.contains(query.toLowerCase()) ||
            estado.contains(query.toLowerCase());
      }).toList();

      emit(currentState.copyWith(
          inscripcionesFiltradas: inscripcionesFiltradas));
    }
  }

  // ==================== GESTIÓN DE INSCRIPCIONES ====================
  Future<void> crearInscripcion(Map<String, dynamic> datosInscripcion) async {
    if (state is! InscripcionLoaded) return;
    final currentState = state as InscripcionLoaded;
    emit(InscripcionLoading());
    try {
      final nuevaInscripcion =
          await _repository.crearInscripcion(datosInscripcion);
      final nuevasInscripciones = [
        ...currentState.inscripciones,
        nuevaInscripcion
      ];
      emit(InscripcionLoaded(
        inscripciones: nuevasInscripciones,
        inscripcionesFiltradas: nuevasInscripciones,
      ));
    } catch (e) {
      emit(InscripcionError(error: e.toString()));
      await cargarInscripciones();
    }
  }

  Future<void> cancelarInscripcion(int inscripcionId, String motivo) async {
    if (state is! InscripcionLoaded) return;
    try {
      await _repository.cancelarInscripcion(inscripcionId, motivo);
      await cargarInscripciones();
    } catch (e) {
      emit(InscripcionError(error: e.toString()));
      await cargarInscripciones();
    }
  }

  Future<void> reactivarInscripcion(int inscripcionId) async {
    if (state is! InscripcionLoaded) return;
    try {
      await _repository.reactivarInscripcion(inscripcionId);
      await cargarInscripciones();
    } catch (e) {
      emit(InscripcionError(error: e.toString()));
      await cargarInscripciones();
    }
  }

  Future<void> completarInscripcion(int inscripcionId) async {
    if (state is! InscripcionLoaded) return;
    try {
      await _repository.completarInscripcion(inscripcionId);
      await cargarInscripciones();
    } catch (e) {
      emit(InscripcionError(error: e.toString()));
      await cargarInscripciones();
    }
  }

  // ==================== REPORTES ====================
  Future<List<dynamic>> generarReporteClasesPopulares() async {
    try {
      return await _repository.generarReporteClasesPopulares();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<dynamic>> generarReporteClientesActivos() async {
    try {
      return await _repository.generarReporteClientesActivos();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==================== ALERTAS DE CUPOS CRÍTICOS ====================
  Future<void> cargarAlertasCuposCriticos({int porcentaje = 80}) async {
    try {
      final alertas = await _repository.obtenerAlertasCuposCriticos(porcentaje);
      emit(InscripcionAlertasLoaded(alertas: alertas));
    } catch (e) {
      emit(InscripcionError(
          error: 'Error al obtener alertas de cupos críticos: $e'));
    }
  }

  // ==================== UTILIDADES ====================
  void clearError() {
    if (state is InscripcionError) {
      final currentState = state as InscripcionError;
      emit(InscripcionLoaded(
        inscripciones: currentState.inscripciones,
        inscripcionesFiltradas: currentState.inscripciones,
      ));
    }
  }
}
