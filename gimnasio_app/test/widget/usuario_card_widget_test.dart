import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/Widgets/usuario_card_widget.dart';
import 'package:gimnasio_app/Cubits/usuario_cubit.dart';
import 'package:gimnasio_app/repositorio_api/usuario_repositorio.dart';
import 'package:dio/dio.dart';

class FakeUsuarioRepository extends UsuarioRepository {
  FakeUsuarioRepository() : super(dio: Dio(), baseUrl: '');
  Future<Map<String, dynamic>> activarUsuario(int usuarioId) async => {};
  Future<Map<String, dynamic>> actualizarUsuario(
          int usuarioId, Map<String, dynamic> datos) async =>
      {};
  Future<Map<String, dynamic>> crearUsuario(
          Map<String, dynamic> datosUsuario) async =>
      {};
  Future<Map<String, dynamic>> desactivarUsuario(int usuarioId) async => {};
  Future<Map<String, dynamic>> eliminarUsuario(int usuarioId) async => {};
  Future<List<dynamic>> obtenerTodosLosUsuarios(
          {bool? soloActivos, String? filtroNombre, String? filtroDni}) async =>
      [];
  Future<Map<String, dynamic>> obtenerDetalleUsuario(int usuarioId) async =>
      {'id': usuarioId, 'nombre': 'Test'};
  Future<Map<String, dynamic>> obtenerEstadisticasUsuarios() async => {};
  Future<Map<String, dynamic>> obtenerDashboardUsuarios() async => {};
  Future<Map<String, dynamic>> obtenerUsuarioPorDni(String dni) async => {};
}

void main() {
  testWidgets('UsuarioCardWidget muestra nombre y DNI',
      (WidgetTester tester) async {
    final usuario = {'id': 1, 'nombre': 'Pedro', 'dni': '999', 'activo': true};

    final cubit = UsuarioCubit(repository: FakeUsuarioRepository() as dynamic);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<UsuarioCubit>.value(
        value: cubit,
        child: UsuarioCardWidget(usuario: usuario),
      ),
    ));

    expect(find.textContaining('Pedro'), findsOneWidget);
    expect(find.textContaining('999'), findsOneWidget);
  });
}
