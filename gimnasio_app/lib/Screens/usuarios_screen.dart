import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Cubits/usuario_cubit.dart';
import 'package:gimnasio_app/Widgets/usuario_card_widget.dart';
import 'package:gimnasio_app/Widgets/crear_usuario_widget.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UsuarioCubit>().cargarUsuarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _mostrarCrear() {
    showDialog(
        context: context, builder: (_) => Dialog(child: CrearUsuarioWidget()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios'), actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UsuarioCubit>().cargarUsuarios()),
        IconButton(icon: const Icon(Icons.add), onPressed: _mostrarCrear)
      ]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre o DNI'),
                onChanged: (v) =>
                    context.read<UsuarioCubit>().filtrarUsuarios(v))),
        Expanded(child:
            BlocBuilder<UsuarioCubit, UsuarioState>(builder: (context, state) {
          if (state is UsuarioLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is UsuarioError)
            return Center(child: Text('Error: ${state.message}'));
          if (state is UsuarioLoaded) {
            final list = state.usuariosFiltrados;
            if (list.isEmpty) return const Center(child: Text('Sin usuarios'));
            return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) =>
                    UsuarioCardWidget(usuario: list[index]));
          }
          return const Center(child: Text('Sin datos'));
        }))
      ]),
    );
  }
}
