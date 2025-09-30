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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Aquí puedes mostrar el contenido del reporte
              // Por ahora mostramos un placeholder
              _buildPlaceholderReporte(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderReporte() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.analytics, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Contenido del Reporte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Este es un placeholder para el reporte: $titulo',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (reporte != null) Text('Datos: $reporte'),
          ],
        ),
      ),
    );
  }
}
