import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/mercado_pago_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

/// Widget para crear un pago. Llama a [MercadoPagoCubit.crearPago]
/// Si el backend retorna una preferencia con `init_point` (URL), se la devuelve
/// al llamador mediante `onPreferenciaCreada`.
class CrearPagoWidget extends StatefulWidget {
  final void Function(String? initPoint)? onPreferenciaCreada;
  final Map<String, dynamic>? pagoInicial;

  const CrearPagoWidget(
      {super.key, this.onPreferenciaCreada, this.pagoInicial});

  @override
  State<CrearPagoWidget> createState() => _CrearPagoWidgetState();
}

class _CrearPagoWidgetState extends State<CrearPagoWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _clienteCtrl = TextEditingController();
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    // Prefill si venimos en modo edición
    final inicial = widget.pagoInicial;
    if (inicial != null) {
      if (inicial['monto'] != null) {
        _montoCtrl.text = inicial['monto'].toString();
      }
      if (inicial['descripcion'] != null) {
        _descripcionCtrl.text = inicial['descripcion'].toString();
      }
      if (inicial['cliente'] != null) {
        _clienteCtrl.text = inicial['cliente'].toString();
      }
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    _clienteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final cubit = context.read<MercadoPagoCubit>();
    final datos = {
      'monto': double.tryParse(_montoCtrl.text) ?? 0.0,
      'descripcion': _descripcionCtrl.text,
      'cliente': _clienteCtrl.text,
    };

    try {
      // Se asume que el backend ofrece un endpoint para crear preferencia
      // y que el cubit expone ese comportamiento.
      final preferencia = await cubit.crearPreferencia({
        'items': [
          {
            'title': _descripcionCtrl.text,
            'quantity': 1,
            'unit_price': datos['monto'],
          }
        ],
        'payer': {'name': _clienteCtrl.text},
      });

      String? initPoint;
      if (preferencia.containsKey('init_point')) {
        initPoint = preferencia['init_point'] as String?;
      }

      // Llamar al crearPago para registrar en el backend
      // Si recibimos pagoInicial -> modo edición
      if (widget.pagoInicial != null && widget.pagoInicial!.containsKey('id')) {
        final id = widget.pagoInicial!['id'] as int;
        await cubit.actualizarPago(id, {
          'monto': datos['monto'],
          'descripcion': datos['descripcion'],
          'cliente': datos['cliente'],
          'preferencia': preferencia,
        });
      } else {
        // Llamar al crearPago para registrar en el backend
        await cubit.crearPago({
          'monto': datos['monto'],
          'descripcion': datos['descripcion'],
          'cliente': datos['cliente'],
          'preferencia': preferencia,
        });
      }

      if (widget.onPreferenciaCreada != null)
        widget.onPreferenciaCreada!(initPoint);
      if (mounted) {
        AppSnackBar.show(context, 'Pago guardado correctamente');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error creando pago: ${e.toString()}',
            error: true);
      }
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
            Text('Crear Pago', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa un monto';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa una descripción' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _clienteCtrl,
              decoration:
                  const InputDecoration(labelText: 'Cliente (nombre o DNI)'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa cliente' : null,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                        : const Text('Crear')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
