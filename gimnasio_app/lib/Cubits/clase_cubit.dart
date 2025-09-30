// cubits/clase_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:gimnasio_app/repositorio_api/clase_repositorio.dart';

part 'clase_state.dart';

class ClaseCubit extends Cubit<ClaseState> {
  final ClaseRepository _repository;

  ClaseCubit({required ClaseRepository repository})
      : _repository = repository,
        super(ClaseInitial());

  // ==================== CARGA DE CLASES ====================
  Future<void> cargarClases() async {
    try {
      emit(ClaseLoading());
      final clases = await _repository.obtenerTodasLasClases();

      // Asegurar que la lista sea del tipo correcto
      final List<Map<String, dynamic>> clasesTyped =
          clases.cast<Map<String, dynamic>>();

      emit(ClaseLoaded(
        clases: clasesTyped,
        clasesFiltradas: clasesTyped,
      ));
    } catch (e) {
      emit(ClaseError(message: e.toString()));
    }
  }

  // ==================== FILTRADO ====================
  void filtrarClases({
    String? nombre,
    bool? soloActivas,
    String? dificultad,
    String? instructor,
  }) {
    if (state is! ClaseLoaded) return;

    final currentState = state as ClaseLoaded;
    List<Map<String, dynamic>> clasesFiltradas = currentState.clases;

    // Aplicar filtros en cascada
    if (nombre != null && nombre.isNotEmpty) {
      clasesFiltradas = clasesFiltradas
          .where((clase) =>
              clase['nombre'].toLowerCase().contains(nombre.toLowerCase()))
          .toList();
    }

    if (soloActivas != null) {
      clasesFiltradas = clasesFiltradas
          .where((clase) => clase['activa'] == soloActivas)
          .toList();
    }

    if (dificultad != null && dificultad != 'todas') {
      clasesFiltradas = clasesFiltradas
          .where((clase) => clase['dificultad'] == dificultad)
          .toList();
    }

    if (instructor != null && instructor != 'todos') {
      clasesFiltradas = clasesFiltradas
          .where((clase) => clase['instructor'] == instructor)
          .toList();
    }

    emit(currentState.copyWith(clasesFiltradas: clasesFiltradas));
  }

  // ==================== GESTIÓN DE CLASES ====================
  Future<void> crearClase(Map<String, dynamic> datosClase) async {
    try {
      if (state is! ClaseLoaded) return;

      emit(ClaseLoading());
      await _repository.crearClase(datosClase);
      await cargarClases(); // Recargar la lista actualizada
    } catch (e) {
      emit(ClaseError(message: 'Error al crear clase: ${e.toString()}'));
      // Restaurar estado anterior
      if (state is! ClaseLoaded) {
        await cargarClases();
      }
    }
  }

  Future<void> actualizarClase(int claseId, Map<String, dynamic> datos) async {
    try {
      if (state is! ClaseLoaded) return;

      emit(ClaseLoading());
      await _repository.actualizarClase(claseId, datos);
      await cargarClases(); // Recargar la lista actualizada
    } catch (e) {
      emit(ClaseError(message: 'Error al actualizar clase: ${e.toString()}'));
      if (state is! ClaseLoaded) {
        await cargarClases();
      }
    }
  }

  Future<void> activarClase(int claseId) async {
    try {
      if (state is! ClaseLoaded) return;

      await _repository.activarClase(claseId);
      await cargarClases();
    } catch (e) {
      emit(ClaseError(message: 'Error al activar clase: ${e.toString()}'));
    }
  }

  Future<void> desactivarClase(int claseId) async {
    try {
      if (state is! ClaseLoaded) return;

      await _repository.desactivarClase(claseId);
      await cargarClases();
    } catch (e) {
      emit(ClaseError(message: 'Error al desactivar clase: ${e.toString()}'));
    }
  }

  Future<void> duplicarClase(int claseId, String nuevoNombre) async {
    try {
      if (state is! ClaseLoaded) return;

      await _repository.duplicarClase(claseId, nuevoNombre);
      await cargarClases();
    } catch (e) {
      emit(ClaseError(message: 'Error al duplicar clase: ${e.toString()}'));
    }
  }

  // ==================== OBTENER DATOS PARA FILTROS ====================
  List<String> obtenerInstructoresUnicos() {
    if (state is! ClaseLoaded) return [];

    final currentState = state as ClaseLoaded;
    final instructores = currentState.clases
        .map<String>((clase) => clase['instructor'].toString())
        .toSet()
        .toList();

    instructores.sort();
    return instructores;
  }

  // ==================== REPORTES ====================
  Future<List<Map<String, dynamic>>> generarReporteOcupacion() async {
    try {
      final reporte = await _repository.generarReporteOcupacion();
      return reporte.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error al generar reporte: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> generarReporteDificultad() async {
    try {
      return await _repository.generarReporteDificultad();
    } catch (e) {
      throw Exception('Error al generar reporte: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> generarReporteInstructores() async {
    try {
      return await _repository.generarReporteInstructores();
    } catch (e) {
      throw Exception('Error al generar reporte: ${e.toString()}');
    }
  }

  // ==================== ESTADÍSTICAS ====================
  Future<Map<String, dynamic>> obtenerEstadisticasClase(int claseId) async {
    try {
      return await _repository.obtenerEstadisticasClase(claseId);
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  // ==================== INSCRIPCIONES ====================
  Future<List<Map<String, dynamic>>> obtenerInscripcionesClase(
      int claseId) async {
    try {
      final inscripciones =
          await _repository.obtenerInscripcionesClase(claseId);
      return inscripciones.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error al obtener inscripciones: ${e.toString()}');
    }
  }
}
