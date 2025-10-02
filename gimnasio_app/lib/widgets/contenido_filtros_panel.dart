// widgets/contenido_filtros_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/cubits/contenido_cubit.dart';

class ContenidoFiltrosPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String categoriaFiltro;
  final String tipoArchivoFiltro;
  final ValueChanged<String> onCategoriaChanged;
  final ValueChanged<String> onTipoArchivoChanged;
  final VoidCallback onLimpiarFiltros;

  const ContenidoFiltrosPanel({
    Key? key,
    required this.searchController,
    required this.categoriaFiltro,
    required this.tipoArchivoFiltro,
    required this.onCategoriaChanged,
    required this.onTipoArchivoChanged,
    required this.onLimpiarFiltros,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del panel de filtros
          _buildTituloPanel(),
          const SizedBox(height: 12),

          // Filtros en fila
          _buildFiltrosFila(context),
        ],
      ),
    );
  }

  Widget _buildTituloPanel() {
    return Row(
      children: [
        const Icon(Icons.filter_list, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          'Filtrar contenido:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const Spacer(),
        if (_hayFiltrosActivos) _buildBotonLimpiar(),
      ],
    );
  }

  Widget _buildBotonLimpiar() {
    return GestureDetector(
      onTap: onLimpiarFiltros,
      child: Row(
        children: [
          Text(
            'Limpiar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.clear, size: 16, color: Colors.blue[700]),
        ],
      ),
    );
  }

  Widget _buildFiltrosFila(BuildContext context) {
    return Row(
      children: [
        // Filtro por categoría
        Expanded(
          child: _buildFiltroCategoria(),
        ),
        const SizedBox(width: 12),

        // Filtro por tipo de archivo
        Expanded(
          child: _buildFiltroTipoArchivo(),
        ),
      ],
    );
  }

  Widget _buildFiltroCategoria() {
    return BlocBuilder<ContenidoCubit, ContenidoState>(
      builder: (context, state) {
        List<String> categorias = ['todas'];
        if (state is ContenidoLoaded) {
          categorias = ['todas', ...state.categorias];
        }

        // Asegurarse de que la categoría seleccionada esté en la lista
        final categoriaActual =
            categorias.contains(categoriaFiltro) ? categoriaFiltro : 'todas';

        return DropdownButtonFormField<String>(
          value: categoriaActual,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: categorias.map((categoria) {
            return DropdownMenuItem(
              value: categoria,
              child: Text(
                categoria == 'todas'
                    ? 'Todas las categorías'
                    : _getTextoCategoria(categoria),
                style: TextStyle(
                  fontWeight: categoria == categoriaActual
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            onCategoriaChanged(value ?? 'todas');
          },
        );
      },
    );
  }

  Widget _buildFiltroTipoArchivo() {
    final List<String> tiposArchivo = [
      'todos',
      'imagen',
      'video',
      'pdf',
      'documento',
      'audio',
      'enlace'
    ];

    return DropdownButtonFormField<String>(
      value: tipoArchivoFiltro,
      decoration: const InputDecoration(
        labelText: 'Tipo de archivo',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: tiposArchivo.map((tipo) {
        return DropdownMenuItem(
          value: tipo,
          child: Text(
            tipo == 'todos' ? 'Todos los tipos' : _getTextoTipoArchivo(tipo),
            style: TextStyle(
              fontWeight: tipo == tipoArchivoFiltro
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        onTipoArchivoChanged(value ?? 'todos');
      },
    );
  }

  String _getTextoCategoria(String categoria) {
    switch (categoria) {
      case 'ejercicios':
        return 'Ejercicios';
      case 'nutricion':
        return 'Nutrición';
      case 'rutinas':
        return 'Rutinas';
      case 'tecnica':
        return 'Técnica';
      case 'salud':
        return 'Salud';
      case 'general':
        return 'General';
      default:
        return categoria;
    }
  }

  String _getTextoTipoArchivo(String tipo) {
    switch (tipo) {
      case 'imagen':
        return 'Imagen';
      case 'video':
        return 'Video';
      case 'pdf':
        return 'PDF';
      case 'documento':
        return 'Documento';
      case 'audio':
        return 'Audio';
      case 'enlace':
        return 'Enlace';
      default:
        return tipo;
    }
  }

  bool get _hayFiltrosActivos =>
      categoriaFiltro != 'todas' ||
      tipoArchivoFiltro != 'todos' ||
      searchController.text.isNotEmpty;
}
