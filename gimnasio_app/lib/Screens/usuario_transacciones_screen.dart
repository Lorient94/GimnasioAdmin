// screens/usuario_transacciones_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/transaccion_cubit.dart';
import 'package:gimnasio_app/Widgets/transaccion_card_widget.dart';

class UsuarioTransaccionesScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const UsuarioTransaccionesScreen({super.key, required this.usuario});

  @override
  State<UsuarioTransaccionesScreen> createState() =>
      _UsuarioTransaccionesScreenState();
}

class _UsuarioTransaccionesScreenState
    extends State<UsuarioTransaccionesScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar transacciones específicas del usuario
    final dni = widget.usuario['dni']?.toString();
    if (dni != null) {
      context.read<TransaccionCubit>().cargarTransaccionesPorCliente(dni);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transacciones de ${widget.usuario['nombre']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final dni = widget.usuario['dni']?.toString();
              if (dni != null) {
                context
                    .read<TransaccionCubit>()
                    .cargarTransaccionesPorCliente(dni);
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<TransaccionCubit, TransaccionState>(
        builder: (context, state) {
          if (state is TransaccionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TransaccionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final dni = widget.usuario['dni']?.toString();
                      if (dni != null) {
                        context
                            .read<TransaccionCubit>()
                            .cargarTransaccionesPorCliente(dni);
                      }
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is TransaccionLoaded) {
            final transaccionesUsuario = state.transaccionesFiltradas
                .where((transaccion) =>
                    transaccion['cliente_dni']?.toString() ==
                    widget.usuario['dni']?.toString())
                .toList();

            if (transaccionesUsuario.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No hay transacciones',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: transaccionesUsuario.length,
              itemBuilder: (context, index) {
                return TransaccionCardWidget(
                    transaccion: transaccionesUsuario[index]);
              },
            );
          }

          return const Center(child: Text('Cargando transacciones...'));
        },
      ),
    );
  }
}
