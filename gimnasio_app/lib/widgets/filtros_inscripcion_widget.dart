// widgets/filtros_inscripcion_widget.dart
import 'package:flutter/material.dart';

class FiltrosInscripcionWidget extends StatefulWidget {
  final Function(Map<String, dynamic> filtros) onFiltrosCambiados;

  const FiltrosInscripcionWidget({
    Key? key,
    required this.onFiltrosCambiados,
  }) : super(key: key);

  @override
  State<FiltrosInscripcionWidget> createState() =>
      _FiltrosInscripcionWidgetState();
}

class _FiltrosInscripcionWidgetState extends State<FiltrosInscripcionWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroEstado = 'todos';
  String _filtroCliente = '';
  String _fechaInicio = '';
  String _fechaFin = '';

  @override
  void initState() {
    super.initState();
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final filtros = {
      'query': _searchController.text,
      'estado': _filtroEstado == 'todos' ? null : _filtroEstado,
      'clienteDni': _filtroCliente.isEmpty ? null : _filtroCliente,
      'fechaInicio': _fechaInicio.isEmpty ? null : _fechaInicio,
      'fechaFin': _fechaFin.isEmpty ? null : _fechaFin,
    };
    widget.onFiltrosCambiados(filtros);
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        } else {
          _fechaFin =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        }
      });
      _aplicarFiltros();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, email o clase...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _aplicarFiltros();
                  },
                ),
              ),
              onChanged: (_) => _aplicarFiltros(),
            ),
            const SizedBox(height: 10),

            // Filtros
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFiltroDropdown(
                  value: _filtroEstado,
                  items: const [
                    DropdownMenuItem(
                        value: 'todos', child: Text('Todos los estados')),
                    DropdownMenuItem(value: 'activa', child: Text('Activas')),
                    DropdownMenuItem(
                        value: 'cancelada', child: Text('Canceladas')),
                    DropdownMenuItem(
                        value: 'completada', child: Text('Completadas')),
                    DropdownMenuItem(
                        value: 'pendiente', child: Text('Pendientes')),
                  ],
                  onChanged: (value) {
                    setState(() => _filtroEstado = value!);
                    _aplicarFiltros();
                  },
                  label: 'Estado',
                ),
                _buildFiltroTexto(
                  controller: TextEditingController(text: _filtroCliente),
                  hintText: 'DNI del cliente',
                  onChanged: (value) {
                    _filtroCliente = value;
                    _aplicarFiltros();
                  },
                  label: 'Cliente DNI',
                ),
                _buildFiltroFecha(
                  label: 'Fecha Inicio',
                  value: _fechaInicio,
                  onTap: () => _seleccionarFecha(context, true),
                ),
                _buildFiltroFecha(
                  label: 'Fecha Fin',
                  value: _fechaFin,
                  onTap: () => _seleccionarFecha(context, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return Container(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            isDense: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroTexto({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required String label,
  }) {
    return Container(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroFecha({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(value.isEmpty ? 'Seleccionar fecha' : value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
