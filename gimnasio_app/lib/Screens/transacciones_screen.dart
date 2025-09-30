import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/transaccion_cubit.dart';
import 'package:gimnasio_app/Widgets/transaccion_card_widget.dart';
import 'package:gimnasio_app/Widgets/crear_transaccion_widget.dart';

class TransaccionesScreen extends StatefulWidget {
  const TransaccionesScreen({super.key});

  @override
  State<TransaccionesScreen> createState() => _TransaccionesScreenState();
}

class _TransaccionesScreenState extends State<TransaccionesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TransaccionCubit>().cargarTransacciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _mostrarCrear() {
    showDialog(
        context: context,
        builder: (_) => Dialog(child: CrearTransaccionWidget()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<TransaccionCubit>().cargarTransacciones()),
          IconButton(icon: const Icon(Icons.add), onPressed: _mostrarCrear),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por cliente, estado o referencia'),
                onChanged: (v) =>
                    context.read<TransaccionCubit>().filtrarTransacciones(v)),
          ),
          Expanded(child: BlocBuilder<TransaccionCubit, TransaccionState>(
              builder: (context, state) {
            if (state is TransaccionLoading)
              return const Center(child: CircularProgressIndicator());
            if (state is TransaccionError)
              return Center(child: Text('Error: ${state.message}'));
            if (state is TransaccionLoaded) {
              final list = state.transaccionesFiltradas;
              if (list.isEmpty)
                return const Center(child: Text('Sin transacciones'));
              return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      TransaccionCardWidget(transaccion: list[index]));
            }
            return const Center(child: Text('Sin datos'));
          }))
        ],
      ),
    );
  }
}
