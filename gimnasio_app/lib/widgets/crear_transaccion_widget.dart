import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/transaccion_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class CrearTransaccionWidget extends StatefulWidget {
  final Map<String, dynamic>? transaccionInicial;
  const CrearTransaccionWidget({super.key, this.transaccionInicial});

  @override
  State<CrearTransaccionWidget> createState() => _CrearTransaccionWidgetState();
}

class _CrearTransaccionWidgetState extends State<CrearTransaccionWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clienteCtrl = TextEditingController();
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaccionInicial;
    if (t != null) {
      if (t['cliente'] != null) _clienteCtrl.text = t['cliente'].toString();
      if (t['monto'] != null) _montoCtrl.text = t['monto'].toString();
      if (t['descripcion'] != null)
        _descripcionCtrl.text = t['descripcion'].toString();
    }
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final cubit = context.read<TransaccionCubit>();
    final datos = {
      'cliente': _clienteCtrl.text,
      'monto': double.tryParse(_montoCtrl.text) ?? 0.0,
      'descripcion': _descripcionCtrl.text,
    };
    try {
      if (widget.transaccionInicial != null &&
          widget.transaccionInicial!.containsKey('id')) {
        final id = widget.transaccionInicial!['id'] as int;
        await cubit.actualizarTransaccion(id, datos);
      } else {
        await cubit.crearTransaccion(datos);
      }
      if (mounted) {
        AppSnackBar.show(context, 'Transacción guardada correctamente');
        Navigator.of(context).pop();
      }
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
                widget.transaccionInicial != null
                    ? 'Editar Transacción'
                    : 'Crear Transacción',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
                controller: _clienteCtrl,
                decoration: const InputDecoration(labelText: 'Cliente'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa cliente' : null),
            const SizedBox(height: 8),
            TextFormField(
                controller: _montoCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto'),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) return 'Monto inválido';
                  return null;
                }),
            const SizedBox(height: 8),
            TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción')),
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
