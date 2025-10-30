import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/transaccion_cubit.dart';
import 'package:gimnasio_app/utils/snackbars.dart';

class CrearTransaccionWidget extends StatefulWidget {
  final Map<String, dynamic>? transaccionInicial;
  final VoidCallback? onTransaccionCreada; // ✅ Nuevo parámetro para callback

  const CrearTransaccionWidget({
    super.key,
    this.transaccionInicial,
    this.onTransaccionCreada,
  });

  @override
  State<CrearTransaccionWidget> createState() => _CrearTransaccionWidgetState();
}

class _CrearTransaccionWidgetState extends State<CrearTransaccionWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clienteDniCtrl = TextEditingController();
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _conceptoCtrl = TextEditingController();
  final TextEditingController _referenciaCtrl = TextEditingController();
  final TextEditingController _observacionesCtrl = TextEditingController();

  String _metodoPagoSeleccionado = 'mercado_pago';
  String _estadoSeleccionado = 'pendiente';
  bool _loading = false;

  // Opciones para los dropdowns
  final List<Map<String, String>> _metodosPago = [
    {'value': 'mercado_pago', 'label': 'Mercado Pago'},
    {'value': 'efectivo', 'label': 'Efectivo'},
    {'value': 'transferencia', 'label': 'Transferencia'},
    {'value': 'tarjeta de crédito', 'label': 'Tarjeta de Crédito'},
    {'value': 'tarjeta de débito', 'label': 'Tarjeta de Débito'},
    {'value': 'billetera virtual', 'label': 'Billetera Virtual'},
  ];

  final List<Map<String, String>> _estados = [
    {'value': 'pendiente', 'label': 'Pendiente'},
    {'value': 'completada', 'label': 'Completada'},
    {'value': 'rechazada', 'label': 'Rechazada'},
    {'value': 'cancelada', 'label': 'Cancelada'},
    {'value': 'reembolsada', 'label': 'Reembolsada'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    final t = widget.transaccionInicial;
    if (t != null) {
      // Cargar datos existentes para edición
      if (t['cliente_dni'] != null)
        _clienteDniCtrl.text = t['cliente_dni'].toString();
      if (t['monto'] != null) _montoCtrl.text = t['monto'].toString();
      if (t['concepto'] != null) _conceptoCtrl.text = t['concepto'].toString();
      if (t['referencia'] != null)
        _referenciaCtrl.text = t['referencia'].toString();
      if (t['observaciones'] != null)
        _observacionesCtrl.text = t['observaciones'].toString();
      if (t['metodo_pago'] != null)
        _metodoPagoSeleccionado = t['metodo_pago'].toString();
      if (t['estado'] != null) _estadoSeleccionado = t['estado'].toString();
    } else {
      // Generar referencia automática para nueva transacción
      _referenciaCtrl.text = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void dispose() {
    _clienteDniCtrl.dispose();
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    _referenciaCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final cubit = context.read<TransaccionCubit>();

    try {
      final datos = {
        'cliente_dni': _clienteDniCtrl.text.trim(),
        'monto': double.tryParse(_montoCtrl.text) ?? 0.0,
        'concepto': _conceptoCtrl.text.trim(),
        'referencia': _referenciaCtrl.text.trim(),
        'metodo_pago': _metodoPagoSeleccionado,
        'estado': _estadoSeleccionado,
        'observaciones': _observacionesCtrl.text.trim(),
      };

      if (widget.transaccionInicial != null &&
          widget.transaccionInicial!.containsKey('id')) {
        // Modo edición
        final id = widget.transaccionInicial!['id'] as int;
        await cubit.actualizarTransaccion(id, datos);
        if (mounted) {
          AppSnackBar.show(context, 'Transacción actualizada correctamente');
        }
      } else {
        // Modo creación
        await cubit.crearTransaccion(datos);
        if (mounted) {
          AppSnackBar.show(context, 'Transacción creada correctamente');
        }
      }

      if (mounted) {
        // ✅ Ejecutar callback si está definido
        if (widget.onTransaccionCreada != null) {
          widget.onTransaccionCreada!();
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: ${e.toString()}', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdicion = widget.transaccionInicial != null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isEdicion ? Icons.edit : Icons.add,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isEdicion ? 'Editar Transacción' : 'Crear Transacción',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campos del formulario
            TextFormField(
              controller: _clienteDniCtrl,
              decoration: const InputDecoration(
                labelText: 'DNI del Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Ingrese el DNI del cliente';
                }
                if (v.length < 3) {
                  return 'El DNI debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _montoCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val <= 0) {
                  return 'Ingrese un monto válido mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _conceptoCtrl,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Ingrese un concepto para la transacción';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _referenciaCtrl,
              decoration: const InputDecoration(
                labelText: 'Referencia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
                hintText: 'Referencia única de la transacción',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Ingrese una referencia para la transacción';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Dropdown de método de pago
            _buildDropdown(
              label: 'Método de Pago',
              value: _metodoPagoSeleccionado,
              items: _metodosPago,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _metodoPagoSeleccionado = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione un método de pago';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Dropdown de estado (solo en edición)
            if (isEdicion) ...[
              _buildDropdown(
                label: 'Estado',
                value: _estadoSeleccionado,
                items: _estados,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _estadoSeleccionado = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione un estado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],

            // Observaciones (opcional)
            TextFormField(
              controller: _observacionesCtrl,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón cancelar
                TextButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),

                // Botón guardar
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isEdicion ? Icons.save : Icons.add, size: 18),
                            const SizedBox(width: 8),
                            Text(isEdicion ? 'Actualizar' : 'Crear'),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
