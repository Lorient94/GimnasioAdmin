// cubits/contenido_cubit.dart
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

      // Mapear los datos de la API a la estructura esperada por la UI
      final contenidosMapeados = lista.map((item) {
        return _mapearContenidoDesdeAPI(item);
      }).toList();

      // Extraer categorías únicas de los contenidos
      final categoriasUnicas = _extraerCategoriasUnicas(contenidosMapeados);

      emit(ContenidoLoaded(
        contenidos: contenidosMapeados,
        filtradas: contenidosMapeados,
        categorias: categoriasUnicas,
      ));
    } catch (e) {
      emit(ContenidoError(message: e.toString()));
    }
  }

  // Método para mapear los datos de la API a la estructura esperada
  // En el método _mapearContenidoDesdeAPI del ContenidoCubit:

  Map<String, dynamic> _mapearContenidoDesdeAPI(Map<String, dynamic> apiData) {
    // Determinar el tipo de archivo basado exclusivamente en la URL
    String determinarTipoArchivo(String? url) {
      if (url == null || url.isEmpty) return 'documento';

      if (url.toLowerCase().contains('.jpg') ||
          url.toLowerCase().contains('.jpeg') ||
          url.toLowerCase().contains('.png') ||
          url.toLowerCase().contains('.gif') ||
          url.toLowerCase().contains('.webp') ||
          url.toLowerCase().contains('.bmp')) {
        return 'imagen';
      } else if (url.toLowerCase().contains('.mp4') ||
          url.toLowerCase().contains('.avi') ||
          url.toLowerCase().contains('.mov') ||
          url.toLowerCase().contains('.webm') ||
          url.toLowerCase().contains('.mkv')) {
        return 'video';
      } else if (url.toLowerCase().contains('.pdf')) {
        return 'pdf';
      } else if (url.toLowerCase().contains('.mp3') ||
          url.toLowerCase().contains('.wav') ||
          url.toLowerCase().contains('.ogg') ||
          url.toLowerCase().contains('.m4a')) {
        return 'audio';
      } else if (url.toLowerCase().startsWith('http')) {
        return 'enlace';
      } else {
        return 'documento';
      }
    }

    // Mapear categorías de la API a las categorías válidas
    String mapearCategoria(String categoriaAPI) {
      final categoria = categoriaAPI.toLowerCase();

      // Si la categoría de la API ya es una de las válidas, mantenerla
      if (['ejercicios', 'nutricion', 'rutinas', 'tecnica', 'salud', 'general']
          .contains(categoria)) {
        return categoria;
      }

      // Mapear categorías antiguas a las nuevas de forma más conservadora
      switch (categoria) {
        case 'foto':
        case 'imagen':
          return 'ejercicios';
        case 'video':
          return 'ejercicios';
        case 'enlace':
          return 'general'; // Cambiado de 'nutricion' a 'general'
        case 'texto':
          return 'general';
        default:
          return 'general';
      }
    }

    final categoriaAPI = apiData['categoria']?.toString() ?? 'general';
    final url = apiData['url']?.toString();

    return {
      'id': apiData['id'],
      'titulo': apiData['titulo'] ?? 'Sin título',
      'descripcion': apiData['descripcion'] ?? '',
      'categoria': mapearCategoria(categoriaAPI),
      'tipo_archivo': determinarTipoArchivo(url),
      'url_archivo': url,
      'activo': apiData['activo'] ?? true,
      'es_publico': true,
      'fecha_creacion': apiData['fecha_creacion'],
      'fecha_actualizacion': apiData['fecha_actualizacion'],
    };
  }

  List<String> _extraerCategoriasUnicas(List<Map<String, dynamic>> contenidos) {
    final categorias = contenidos
        .map((contenido) => contenido['categoria']?.toString() ?? 'general')
        .where((categoria) => categoria.isNotEmpty)
        .toSet()
        .toList();

    // Ordenar alfabéticamente
    categorias.sort();
    return categorias;
  }

  // ========== MÉTODOS DE FILTRADO ==========

  void filtrarLocalmente(String query) {
    if (state is! ContenidoLoaded) return;
    final current = state as ContenidoLoaded;

    if (query.isEmpty) {
      emit(current.copyWith(filtradas: current.contenidos));
      return;
    }

    final filtradas = current.contenidos.where((contenido) {
      final titulo = contenido['titulo']?.toString().toLowerCase() ?? '';
      final descripcion =
          contenido['descripcion']?.toString().toLowerCase() ?? '';
      final categoria = contenido['categoria']?.toString().toLowerCase() ?? '';

      return titulo.contains(query.toLowerCase()) ||
          descripcion.contains(query.toLowerCase()) ||
          categoria.contains(query.toLowerCase());
    }).toList();

    emit(current.copyWith(filtradas: filtradas));
  }

  void filtrarPorCategoriaYTipo(
      String categoria, String tipoArchivo, String query) {
    if (state is ContenidoLoaded) {
      final currentState = state as ContenidoLoaded;

      List<Map<String, dynamic>> filtradas =
          currentState.contenidos.where((contenido) {
        final categoriaContenido =
            contenido['categoria']?.toString().toLowerCase() ?? '';
        final tipoArchivoContenido =
            contenido['tipo_archivo']?.toString().toLowerCase() ?? '';

        // Verificar filtros de categoría y tipo
        final coincideCategoria = categoria == 'todas' ||
            categoriaContenido == categoria.toLowerCase();
        final coincideTipo = tipoArchivo == 'todos' ||
            tipoArchivoContenido == tipoArchivo.toLowerCase();

        // Si no coincide alguno de los filtros, excluir
        if (!coincideCategoria || !coincideTipo) return false;

        // Si hay query, aplicar búsqueda también
        if (query.isNotEmpty) {
          final titulo = contenido['titulo']?.toString().toLowerCase() ?? '';
          final descripcion =
              contenido['descripcion']?.toString().toLowerCase() ?? '';
          final categoriaBusqueda =
              contenido['categoria']?.toString().toLowerCase() ?? '';

          return titulo.contains(query.toLowerCase()) ||
              descripcion.contains(query.toLowerCase()) ||
              categoriaBusqueda.contains(query.toLowerCase());
        }

        return true;
      }).toList();

      emit(currentState.copyWith(filtradas: filtradas));
    }
  }

  // Método para filtrar solo por categoría
  void filtrarPorCategoria(String categoria, String query) {
    if (state is ContenidoLoaded) {
      final currentState = state as ContenidoLoaded;

      List<Map<String, dynamic>> filtradas =
          currentState.contenidos.where((contenido) {
        final categoriaContenido =
            contenido['categoria']?.toString().toLowerCase() ?? '';

        // Verificar filtro de categoría
        final coincideCategoria = categoria == 'todas' ||
            categoriaContenido == categoria.toLowerCase();

        // Si no coincide la categoría, excluir
        if (!coincideCategoria) return false;

        // Si hay query, aplicar búsqueda también
        if (query.isNotEmpty) {
          final titulo = contenido['titulo']?.toString().toLowerCase() ?? '';
          final descripcion =
              contenido['descripcion']?.toString().toLowerCase() ?? '';
          final categoriaBusqueda =
              contenido['categoria']?.toString().toLowerCase() ?? '';

          return titulo.contains(query.toLowerCase()) ||
              descripcion.contains(query.toLowerCase()) ||
              categoriaBusqueda.contains(query.toLowerCase());
        }

        return true;
      }).toList();

      emit(currentState.copyWith(filtradas: filtradas));
    }
  }

  // Método para limpiar filtros
  void limpiarFiltros() {
    if (state is ContenidoLoaded) {
      final currentState = state as ContenidoLoaded;
      emit(currentState.copyWith(filtradas: currentState.contenidos));
    }
  }

  // ========== MÉTODOS CRUD ==========

  Future<void> crearContenido(Map<String, dynamic> datos) async {
    try {
      if (state is! ContenidoLoaded) emit(ContenidoLoading());

      // Mapear datos para la API
      final datosParaAPI = {
        'titulo': datos['titulo'],
        'descripcion': datos['descripcion'],
        'categoria': datos['categoria'],
        'url': datos['url_archivo'],
        'activo': datos['activo'] ?? true,
      };

      final nuevo = await _repository.crearContenido(datosParaAPI);

      if (state is ContenidoLoaded) {
        final current = state as ContenidoLoaded;
        final nuevoMapeado = _mapearContenidoDesdeAPI(nuevo);
        final nuevos = [...current.contenidos, nuevoMapeado];

        final nuevasCategorias = _extraerCategoriasUnicas(nuevos);

        emit(current.copyWith(
          contenidos: nuevos,
          filtradas: nuevos,
          categorias: nuevasCategorias,
        ));
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

      // Mapear datos para la API
      final datosParaAPI = {
        'titulo': datos['titulo'],
        'descripcion': datos['descripcion'],
        'categoria': datos['categoria'],
        'url': datos['url_archivo'],
        'activo': datos['activo'] ?? true,
      };

      await _repository.actualizarContenido(id, datosParaAPI);
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

  Future<void> eliminarContenido(int id) async {
    try {
      await _repository.desactivarContenido(id);
      await cargarContenidos();
    } catch (e) {
      emit(ContenidoError(message: e.toString()));
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleContenido(int contenidoId) async {
    try {
      final detalle = await _repository.obtenerDetalleContenido(contenidoId);
      return _mapearContenidoDesdeAPI(detalle);
    } catch (e) {
      throw Exception('Error al obtener detalle: $e');
    }
  }

  Future<List<String>> obtenerCategoriasDisponibles() async {
    try {
      return await _repository.obtenerCategoriasDisponibles();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  // Métodos para reportes
  Future<List<dynamic>> generarReporteCategorias() async {
    try {
      return await _repository.generarReporteCategorias();
    } catch (e) {
      throw Exception('Error al generar reporte: $e');
    }
  }

  Future<Map<String, dynamic>> generarReporteTiposContenido() async {
    try {
      return await _repository.generarReporteTiposContenido();
    } catch (e) {
      throw Exception('Error al generar reporte tipos: $e');
    }
  }
}
