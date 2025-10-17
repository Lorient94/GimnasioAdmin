import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/mercado_pago_cubit.dart';
import 'package:gimnasio_app/repositorio_api/usuario_repositorio.dart';
import 'package:dio/dio.dart';

class CrearPagoWidget extends StatefulWidget {
  final void Function(String? initPoint) onPreferenciaCreada;
  final Map<String, dynamic>? pagoInicial; // <-- nuevo parámetro opcional

  const CrearPagoWidget({
    super.key,
    required this.onPreferenciaCreada,
    this.pagoInicial,
  });

  @override
  State<CrearPagoWidget> createState() => _CrearPagoWidgetState();
}

class _CrearPagoWidgetState extends State<CrearPagoWidget> {
  final _formKey = GlobalKey<FormState>();
  String? _clienteDni;
  double? _monto;
  String? _concepto;

  List<Map<String, dynamic>> _clientes = [];
  bool _loadingClientes = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarClientes();

    // Si viene pagoInicial, prellenar campos
    if (widget.pagoInicial != null) {
      final pago = widget.pagoInicial!;
      _clienteDni = pago['cliente_dni']?.toString();
      _monto = pago['monto'] != null
          ? double.tryParse(pago['monto'].toString())
          : null;
      _concepto = pago['concepto']?.toString();
    }
  }

  Future<void> _cargarClientes() async {
    try {
      final repo = UsuarioRepository(
        dio: Dio(),
        baseUrl: const String.fromEnvironment('BACKEND_URL',
            defaultValue: 'http://localhost:8000'),
      );

      final clientes = await repo.obtenerTodosLosUsuarios();
      setState(() {
        _clientes = List<Map<String, dynamic>>.from(clientes);
        _loadingClientes = false;
      });
    } catch (e) {
      setState(() => _loadingClientes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar clientes: $e')),
      );
    }
  }

  Future<void> _crearPago() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _enviando = true);

    try {
      final cubit = context.read<MercadoPagoCubit>();
      final result = await cubit.crearPreferencia({
        "id_usuario": _clienteDni,
        "monto": _monto,
        "concepto": _concepto,
        "metodo_pago": "mercado_pago",
      });

      widget.onPreferenciaCreada(
          result['sandbox_init_point'] ?? result['init_point']);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear pago: $e')),
      );
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.pagoInicial != null
                  ? "Editar pago #${widget.pagoInicial!['id']}"
                  : "Crear nuevo pago",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Dropdown de clientes
            if (_loadingClientes)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              DropdownButtonFormField<String>(
                value: _clienteDni,
                decoration: const InputDecoration(labelText: "Cliente"),
                items: _clientes.map((cliente) {
                  final nombre = cliente['nombre'] ?? '';
                  final apellido = cliente['apellido'] ?? '';
                  final dni = cliente['dni'] ?? '';
                  return DropdownMenuItem(
                    value: dni.toString(),
                    child: Text("$nombre $apellido ($dni)"),
                  );
                }).toList(),
                onChanged: (v) => _clienteDni = v,
                validator: (v) => v == null ? "Selecciona un cliente" : null,
              ),

            const SizedBox(height: 12),

            // Monto
            TextFormField(
              initialValue: _monto?.toString(),
              decoration: const InputDecoration(labelText: "Monto (ARS)"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  v == null || v.isEmpty ? "Campo requerido" : null,
              onSaved: (v) => _monto = double.tryParse(v ?? "0"),
            ),

            const SizedBox(height: 12),

            // Concepto
            TextFormField(
              initialValue: _concepto,
              decoration: const InputDecoration(labelText: "Concepto"),
              validator: (v) =>
                  v == null || v.isEmpty ? "Campo requerido" : null,
              onSaved: (v) => _concepto = v,
            ),

            const SizedBox(height: 24),

            // Botón de crear/editar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _crearPago,
                icon: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(_enviando
                    ? "Procesando..."
                    : (widget.pagoInicial != null
                        ? "Actualizar pago"
                        : "Crear y Pagar")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
