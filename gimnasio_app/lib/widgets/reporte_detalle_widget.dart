// widgets/reporte_detalle_widget.dart
import 'package:flutter/material.dart';

class ReporteDetalleWidget extends StatelessWidget {
  final String titulo;
  final dynamic reporte;
  final VoidCallback onCerrar;

  const ReporteDetalleWidget({
    Key? key,
    required this.titulo,
    required this.reporte,
    required this.onCerrar,
  }) : super(key: key);

  bool _esReporteOcupacion() => reporte is List;

  bool _esReporteDificultad() {
    if (reporte is Map) {
      final keys = (reporte as Map).keys.map((k) => k.toString()).toList();
      return keys.contains('Baja') ||
          keys.contains('Media') ||
          keys.contains('Alta');
    }
    return false;
  }

  bool _esReporteInstructores() {
    if (reporte is Map) {
      final firstValue = (reporte as Map).values.isNotEmpty
          ? (reporte as Map).values.first
          : null;
      return firstValue is Map && firstValue.containsKey('total_clases');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCerrar,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _buildContenido(context),
      ),
    );
  }

  Widget _buildContenido(BuildContext context) {
    if (reporte == null) {
      return Center(
          child: Text('No hay datos para mostrar.',
              style: Theme.of(context).textTheme.bodyMedium));
    }

    if (_esReporteOcupacion())
      return _buildReporteOcupacion(context, reporte as List<dynamic>);
    if (_esReporteDificultad())
      return _buildReporteDificultad(context, reporte as Map<String, dynamic>);
    if (_esReporteInstructores())
      return _buildReporteInstructores(
          context, reporte as Map<String, dynamic>);

    // Fallback: mostrar JSON crudo
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(reporte.toString()),
        ),
      ),
    );
  }

  Widget _buildReporteOcupacion(BuildContext context, List<dynamic> lista) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (lista.isEmpty) {
      return Center(
          child: Text('No hay clases activas para mostrar.',
              style: textTheme.bodyMedium));
    }

    final filledColor = theme.colorScheme.primary;
    final bgBarColor = theme.colorScheme.surfaceVariant;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = lista[index] as Map<String, dynamic>;
        final nombre = item['nombre']?.toString() ?? 'Sin nombre';
        final instructor = item['instructor']?.toString() ?? 'N/A';
        final porcentaje = (item['porcentaje_ocupacion'] is num)
            ? (item['porcentaje_ocupacion'] as num).toDouble()
            : 0.0;
        final cupoMax = item['cupo_maximo']?.toString() ?? '-';
        final inscritos = item['inscripciones_activas']?.toString() ?? '0';

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(nombre,
                            style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 16))),
                    const SizedBox(width: 8),
                    Text('${porcentaje.toStringAsFixed(1)}%',
                        style: textTheme.bodyMedium?.copyWith(fontSize: 14))
                  ],
                ),
                const SizedBox(height: 6),
                Text('Instructor: $instructor', style: textTheme.bodySmall),
                const SizedBox(height: 8),
                LayoutBuilder(builder: (context, constraints) {
                  final barMaxWidth = constraints.maxWidth;
                  final filledWidth =
                      (porcentaje.clamp(0.0, 100.0) / 100.0) * barMaxWidth;
                  return Stack(
                    children: [
                      Container(
                          height: 12,
                          width: barMaxWidth,
                          decoration: BoxDecoration(
                              color: bgBarColor,
                              borderRadius: BorderRadius.circular(6))),
                      Container(
                          height: 12,
                          width: filledWidth,
                          decoration: BoxDecoration(
                              color: filledColor,
                              borderRadius: BorderRadius.circular(6))),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Cupo: $inscritos / $cupoMax',
                        style: textTheme.bodyMedium),
                    const Spacer(),
                    Text('Disponibles: ${item['cupos_disponibles'] ?? '-'}',
                        style: textTheme.bodySmall),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReporteDificultad(
      BuildContext context, Map<String, dynamic> mapa) {
    final niveles = ['Baja', 'Media', 'Alta'];
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        children: niveles.map((nivel) {
          final data = mapa[nivel] ?? {};
          final totalClases = data['total_clases'] ?? 0;
          final totalInscritos = data['total_inscritos'] ?? 0;
          final clases = (data['clases'] as List<dynamic>?) ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            child: ExpansionTile(
              title: Text('$nivel — $totalClases clases',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('$totalInscritos inscritos en total',
                  style: textTheme.bodySmall),
              children: clases.map<Widget>((c) {
                final clase = c as Map<String, dynamic>;
                return ListTile(
                  title: Text(clase['nombre']?.toString() ?? 'Sin nombre',
                      style: textTheme.bodyLarge),
                  subtitle: Text(
                      'Instructor: ${clase['instructor'] ?? '-'} — Inscritos: ${clase['inscritos'] ?? 0}',
                      style: textTheme.bodySmall),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReporteInstructores(
      BuildContext context, Map<String, dynamic> mapa) {
    final entries = mapa.entries.toList();
    final textTheme = Theme.of(context).textTheme;

    if (entries.isEmpty)
      return Center(
          child: Text('No hay instructores con datos.',
              style: textTheme.bodyMedium));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final instructor = entries[index].key.toString();
        final value = entries[index].value as Map<String, dynamic>;
        final totalClases = value['total_clases'] ?? 0;
        final totalInscritos = value['total_inscritos'] ?? 0;
        final clases = (value['clases'] as List<dynamic>?) ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: ExpansionTile(
            title: Text(instructor,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('$totalClases clases — $totalInscritos inscritos',
                style: textTheme.bodySmall),
            children: clases.map<Widget>((c) {
              final clase = c as Map<String, dynamic>;
              return ListTile(
                title: Text(clase['nombre']?.toString() ?? 'Sin nombre',
                    style: textTheme.bodyLarge),
                subtitle: Text(
                    'Horario: ${clase['horario'] ?? '-'} — Dificultad: ${clase['dificultad'] ?? '-'} — Inscritos: ${clase['inscritos'] ?? 0}',
                    style: textTheme.bodySmall),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
