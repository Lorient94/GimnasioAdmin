// widgets/crear_pago_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/mercado_pago_cubit.dart';

class CrearPagoWidget extends StatefulWidget {
  final Function(String?)? onPreferenciaCreada;
  final String? clienteDni;
  final String? clienteNombre;

  const CrearPagoWidget({
    super.key,
    this.onPreferenciaCreada,
    this.clienteDni,
    this.clienteNombre,
  });

  @override
  State<CrearPagoWidget> createState() => _CrearPagoWidgetState();
}

class _CrearPagoWidgetState extends State<CrearPagoWidget> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _conceptoController = TextEditingController();
  final _clienteDniController = TextEditingController();
  final _clienteNombreController = TextEditingController();
  final _clienteEmailController = TextEditingController();

  bool _creando = false;

  @override
  void initState() {
    super.initState();
    // Pre-cargar datos si se proporcionan
    if (widget.clienteDni != null) {
      _clienteDniController.text = widget.clienteDni!;
    }
    if (widget.clienteNombre != null) {
      _clienteNombreController.text = widget.clienteNombre!;
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    _clienteDniController.dispose();
    _clienteNombreController.dispose();
    _clienteEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear Nuevo Pago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // DNI del cliente
            TextFormField(
              controller: _clienteDniController,
              decoration: const InputDecoration(
                labelText: 'DNI del Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el DNI';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Nombre del cliente
            TextFormField(
              controller: _clienteNombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Email del cliente
            TextFormField(
              controller: _clienteEmailController,
              decoration: const InputDecoration(
                labelText: 'Email del Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el email';
                }
                if (!value.contains('@')) {
                  return 'Por favor ingresa un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Monto
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el monto';
                }
                final monto = double.tryParse(value);
                if (monto == null || monto <= 0) {
                  return 'Por favor ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Concepto
            TextFormField(
              controller: _conceptoController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el concepto';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _creando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _creando ? null : _crearPago,
                    child: _creando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear Pago'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearPago() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _creando = true;
    });

    try {
      final cubit = context.read<MercadoPagoCubit>();

      final pagoData = {
        "cliente_dni": _clienteDniController.text,
        "monto": double.parse(_montoController.text),
        "concepto": _conceptoController.text,
        "cliente_nombre": _clienteNombreController.text,
        "cliente_email": _clienteEmailController.text,
      };

      final resultado = await cubit.crearPagoPrueba(pagoData);

      if (mounted) {
        setState(() {
          _creando = false;
        });

        if (resultado['success'] == true) {
          final initPoint = resultado['init_point'];
          widget.onPreferenciaCreada?.call(initPoint);

          // Mostrar éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['message'] ?? 'Pago creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['error'] ?? 'Error al crear pago'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
