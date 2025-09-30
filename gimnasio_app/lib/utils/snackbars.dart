import 'package:flutter/material.dart';

class AppSnackBar {
  static const Duration defaultDuration = Duration(seconds: 3);

  /// Muestra un SnackBar estilizado de la app.
  /// Si [error] es true, usa un color de fondo de error.
  static void show(BuildContext context, String message,
      {bool error = false,
      Duration? duration,
      String? actionLabel,
      VoidCallback? onAction}) {
    final snack = SnackBar(
      content: Text(message),
      duration: duration ?? defaultDuration,
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      action: actionLabel != null
          ? SnackBarAction(label: actionLabel, onPressed: onAction ?? () {})
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }
}
