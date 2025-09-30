// widgets/clase_stats_widget.dart
import 'package:flutter/material.dart';

class ClaseStatsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> clases;
  final Function(Map<String, dynamic>) onVerClase;

  const ClaseStatsWidget({
    Key? key,
    required this.clases,
    required this.onVerClase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clasesActivas = clases.where((c) => c['activa'] == true).length;
    final clasesInactivas = clases.length - clasesActivas;

    // Calcular estadísticas por dificultad
    final dificultades = _calcularEstadisticasDificultad();
    final instructores = _calcularEstadisticasInstructores();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas Generales',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Tarjetas de resumen
          Row(
            children: [
              _buildStatCard('Total Clases', clases.length.toString(),
                  Icons.fitness_center),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Activas', clasesActivas.toString(), Icons.check_circle,
                  color: Colors.green),
              const SizedBox(width: 16),
              _buildStatCard(
                  'Inactivas', clasesInactivas.toString(), Icons.cancel,
                  color: Colors.red),
            ],
          ),

          const SizedBox(height: 24),

          // Estadísticas por dificultad
          _buildDificultadStats(dificultades),

          const SizedBox(height: 24),

          // Estadísticas por instructor
          _buildInstructorStats(instructores),
        ],
      ),
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icon,
      {Color color = Colors.blue}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(titulo, style: const TextStyle(fontSize: 14)),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _calcularEstadisticasDificultad() {
    final Map<String, int> stats = {};
    for (final clase in clases) {
      final dificultad = clase['dificultad'] ?? 'sin especificar';
      stats[dificultad] = (stats[dificultad] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> _calcularEstadisticasInstructores() {
    final Map<String, int> stats = {};
    for (final clase in clases) {
      final instructor = clase['instructor'] ?? 'Sin instructor';
      stats[instructor] = (stats[instructor] ?? 0) + 1;
    }
    return stats;
  }

  Widget _buildDificultadStats(Map<String, int> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clases por Dificultad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...stats.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(entry.value.toString()),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorStats(Map<String, int> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clases por Instructor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...stats.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(entry.key)),
                      Text(entry.value.toString()),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
