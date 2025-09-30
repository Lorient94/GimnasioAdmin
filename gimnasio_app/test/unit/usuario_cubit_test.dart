import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gimnasio_app/Cubits/usuario_cubit.dart';
import 'package:gimnasio_app/repositorio_api/usuario_repositorio.dart';

class MockUsuarioRepository extends Mock implements UsuarioRepository {}

void main() {
  late MockUsuarioRepository mockRepo;
  late UsuarioCubit cubit;

  setUp(() {
    mockRepo = MockUsuarioRepository();
    cubit = UsuarioCubit(repository: mockRepo);
  });

  test('cargarUsuarios emite UsuarioLoaded al obtener lista', () async {
    final sample = [
      {'id': 1, 'nombre': 'Juan', 'dni': '123'},
      {'id': 2, 'nombre': 'Ana', 'dni': '456'}
    ];

    when(() => mockRepo.obtenerTodosLosUsuarios(
        soloActivos: any(named: 'soloActivos'),
        filtroNombre: any(named: 'filtroNombre'),
        filtroDni: any(named: 'filtroDni'))).thenAnswer((_) async => sample);

    await cubit.cargarUsuarios();

    expect(cubit.state, isA<UsuarioLoaded>());
    final state = cubit.state as UsuarioLoaded;
    expect(state.usuarios.length, 2);
    expect(state.usuariosFiltrados.length, 2);
  });
}
