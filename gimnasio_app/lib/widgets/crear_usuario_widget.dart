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
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();
  DateTime? _fechaNacimiento;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.usuarioInicial;
    if (u != null) {
      if (u['nombre'] != null) _nombreCtrl.text = u['nombre'].toString();
      if (u['dni'] != null) _dniCtrl.text = u['dni'].toString();
      if (u['correo'] != null) _correoCtrl.text = u['correo'].toString();
      if (u['telefono'] != null) _telefonoCtrl.text = u['telefono'].toString();
      if (u['ciudad'] != null) _ciudadCtrl.text = u['ciudad'].toString();
      if (u['fecha_nacimiento'] != null) {
        try {
          _fechaNacimiento = DateTime.parse(u['fecha_nacimiento'].toString());
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final cubit = context.read<UsuarioCubit>();
    final datos = {
      'nombre': _nombreCtrl.text,
      'dni': _dniCtrl.text,
      'correo': _correoCtrl.text,
      'telefono': _telefonoCtrl.text,
      'ciudad': _ciudadCtrl.text.isNotEmpty ? _ciudadCtrl.text : null,
      'fecha_nacimiento': _fechaNacimiento != null
          ? _fechaNacimiento!.toIso8601String().split('T').first
          : null,
    };
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
                controller: _correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa correo';
                  final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                  if (!regex.hasMatch(v)) return 'Correo inválido';
                  return null;
                }),
            const SizedBox(height: 8),
            TextFormField(
                controller: _dniCtrl,
                decoration: const InputDecoration(labelText: 'DNI'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa DNI' : null),
            const SizedBox(height: 8),
            TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa teléfono' : null),
            const SizedBox(height: 8),
            TextFormField(
                controller: _ciudadCtrl,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                validator: (v) => null),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text(_fechaNacimiento == null
                    ? 'Fecha de nacimiento no seleccionada'
                    : 'Fecha: ${_fechaNacimiento!.toIso8601String().split('T').first}'),
              ),
              TextButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final initial =
                              _fechaNacimiento ?? DateTime(1990, 1, 1);
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(1900),
                              lastDate: now);
                          if (picked != null)
                            setState(() => _fechaNacimiento = picked);
                        },
                  child: const Text('Seleccionar'))
            ]),
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
