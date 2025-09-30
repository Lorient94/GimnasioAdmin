// widgets/reportes_clase_widget.dart
import 'package:flutter/material.dart';

class ReportesClaseWidget extends StatelessWidget {
  final VoidCallback onGenerarReporteOcupacion;
  final VoidCallback onGenerarReporteDificultad;
  final VoidCallback onGenerarReporteInstructores;

  const ReportesClaseWidget({
    Key? key,
    required this.onGenerarReporteOcupacion,
    required this.onGenerarReporteDificultad,
    required this.onGenerarReporteInstructores,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generar Reportes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildBotonReporte(
            icon: Icons.people,
            titulo: 'Reporte de Ocupación',
            subtitulo: 'Muestra la ocupación de cada clase',
            onTap: onGenerarReporteOcupacion,
          ),
          const SizedBox(height: 16),
          _buildBotonReporte(
            icon: Icons.analytics,
            titulo: 'Reporte por Dificultad',
            subtitulo: 'Clasifica las clases por nivel de dificultad',
            onTap: onGenerarReporteDificultad,
          ),
          const SizedBox(height: 16),
          _buildBotonReporte(
            icon: Icons.person,
            titulo: 'Reporte de Instructores',
            subtitulo: 'Muestra las clases por instructor',
            onTap: onGenerarReporteInstructores,
          ),
        ],
      ),
    );
  }

  Widget _buildBotonReporte({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.green[700]),
        title:
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
