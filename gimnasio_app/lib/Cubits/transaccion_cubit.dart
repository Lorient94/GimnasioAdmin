import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/repositorio_api/transaccion_repositorio.dart';

part 'transaccion_state.dart';

class TransaccionCubit extends Cubit<TransaccionState> {
  final TransaccionRepository _repository;

  TransaccionCubit({required TransaccionRepository repository})
      : _repository = repository,
        super(TransaccionInitial());

  Future<void> cargarTransacciones({
    String? estado,
    String? clienteDni,
    String? metodoPago,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      emit(TransaccionLoading());
      final lista = await _repository.obtenerTodasLasTransacciones(
        estado: estado,
        clienteDni: clienteDni,
        metodoPago: metodoPago,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      final transacciones = List<Map<String, dynamic>>.from(lista);
      emit(TransaccionLoaded(
          transacciones: transacciones, transaccionesFiltradas: transacciones));
    } catch (e) {
      emit(TransaccionError(message: e.toString()));
    }
  }

  Future<Map<String, dynamic>> obtenerDetalle(int id) async {
    try {
      final res = await _repository.obtenerDetalleTransaccion(id);
      return res;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> crearTransaccion(Map<String, dynamic> datos) async {
    try {
      emit(TransaccionLoading());
      final res = await _repository.crearTransaccion(datos);
      if (state is TransaccionLoaded) {
        final current = state as TransaccionLoaded;
        final nuevos = [
          ...current.transacciones,
          Map<String, dynamic>.from(res)
        ];
        emit(current.copyWith(
            transacciones: nuevos, transaccionesFiltradas: nuevos));
      } else {
        await cargarTransacciones();
      }
    } catch (e) {
      emit(TransaccionError(message: e.toString()));
    }
  }

  Future<void> actualizarTransaccion(int id, Map<String, dynamic> datos) async {
    try {
      emit(TransaccionLoading());
      await _repository.actualizarTransaccion(id, datos);
      await cargarTransacciones();
    } catch (e) {
      emit(TransaccionError(message: e.toString()));
    }
  }

  Future<void> cambiarEstado(int id, String estado,
      {String? observaciones}) async {
    try {
      emit(TransaccionLoading());
      await _repository.cambiarEstadoTransaccion(id, estado, observaciones);
      await cargarTransacciones();
    } catch (e) {
      emit(TransaccionError(message: e.toString()));
    }
  }

  Future<void> marcarComoPagada(int id, {String? referenciaPago}) async {
    try {
      emit(TransaccionLoading());
      await _repository.marcarComoPagada(id, referenciaPago: referenciaPago);
      await cargarTransacciones();
    } catch (e) {
      emit(TransaccionError(message: e.toString()));
    }
  }

  Future<void> revertirTransaccion(int id, String motivo) async {
    try {
      emit(TransaccionLoading());
      await _repository.revertirTransaccion(id, motivo);
      await cargarTransacciones();
    } catch (e) {
      emit(TransaccionError(message: e.toString()));
    }
  }

  Future<void> eliminarTransaccion(int id) async {
    try {
      emit(TransaccionLoading());
      await _repository.eliminarTransaccion(id);
      await cargarTransacciones();
    } catch (e) {
      emit(TransaccionError(message: e.toString()));
    }
  }

  /// Filtra las transacciones cargadas en memoria por cliente (dni), estado o referencia.
  /// Si el query está vacío, restaura la lista completa.
  void filtrarTransacciones(String query) {
    final q = query.trim().toLowerCase();
    if (state is TransaccionLoaded) {
      final current = state as TransaccionLoaded;
      if (q.isEmpty) {
        emit(current.copyWith(transaccionesFiltradas: current.transacciones));
        return;
      }
      final filtrados = current.transacciones.where((t) {
        final cliente =
            (t['cliente_dni'] ?? t['cliente'] ?? '').toString().toLowerCase();
        final estado = (t['estado'] ?? '').toString().toLowerCase();
        final referencia =
            (t['referencia_pago'] ?? '').toString().toLowerCase();
        return cliente.contains(q) ||
            estado.contains(q) ||
            referencia.contains(q);
      }).toList();
      emit(current.copyWith(transaccionesFiltradas: filtrados));
    }
  }
}
