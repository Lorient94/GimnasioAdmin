import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/usuario_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class CrearUsuarioWidget extends StatefulWidget {
  final Map<String, dynamic>? usuarioInicial;
  const CrearUsuarioWidget({super.key, this.usuarioInicial});

  @override
  State<CrearUsuarioWidget> createState() => _CrearUsuarioWidgetState();
}

class _CrearUsuarioWidgetState extends State<CrearUsuarioWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _dniCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.usuarioInicial;
    if (u != null) {
      if (u['nombre'] != null) _nombreCtrl.text = u['nombre'].toString();
      if (u['dni'] != null) _dniCtrl.text = u['dni'].toString();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final cubit = context.read<UsuarioCubit>();
    final datos = {'nombre': _nombreCtrl.text, 'dni': _dniCtrl.text};
    try {
      if (widget.usuarioInicial != null &&
          widget.usuarioInicial!.containsKey('id')) {
        await cubit.actualizarUsuario(
            widget.usuarioInicial!['id'] as int, datos);
        if (mounted)
          AppSnackBar.show(context, 'Usuario actualizado correctamente');
      } else {
        await cubit.crearUsuario(datos);
        if (mounted) AppSnackBar.show(context, 'Usuario creado correctamente');
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted)
        AppSnackBar.show(context, 'Error: ${e.toString()}', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                widget.usuarioInicial != null
                    ? 'Editar Usuario'
                    : 'Crear Usuario',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa nombre' : null),
            const SizedBox(height: 8),
            TextFormField(
                controller: _dniCtrl,
                decoration: const InputDecoration(labelText: 'DNI'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa DNI' : null),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar'))
            ])
          ],
        ),
      ),
    );
  }
}
