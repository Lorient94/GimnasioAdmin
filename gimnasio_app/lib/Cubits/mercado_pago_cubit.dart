import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gimnasio_app/repositorio_api/mercado_pago_repositorio.dart';

part 'mercado_pago_state.dart';

class MercadoPagoCubit extends Cubit<MercadoPagoState> {
  final MercadoPagoRepository _repo;
  List<Map<String, dynamic>> _todosLosPagos = [];

  MercadoPagoCubit(this._repo) : super(const MercadoPagoInitial());

  /// Cargar historial completo de pagos
  Future<void> cargarHistorial() async {
    try {
      emit(const MercadoPagoLoading());
      final pagos = await _repo.obtenerHistorialPagos();
      _todosLosPagos = List<Map<String, dynamic>>.from(pagos);
      emit(MercadoPagoLoaded(
          pagos: _todosLosPagos, pagosFiltrados: _todosLosPagos));
    } catch (e) {
      emit(MercadoPagoError('Error al cargar pagos: $e'));
    }
  }

  /// Crear un pago y actualizar la lista
  Future<String?> crearPago(Map<String, dynamic> pagoData) async {
    try {
      emit(const MercadoPagoLoading());
      final result = await _repo.crearPago(pagoData);
      await cargarHistorial();
      return result['sandbox_init_point'] ?? result['init_point'];
    } catch (e) {
      emit(MercadoPagoError('Error al crear pago: $e'));
      return null;
    }
  }

  /// Crear una preferencia de pago
  Future<Map<String, dynamic>> crearPreferencia(
      Map<String, dynamic> data) async {
    try {
      emit(const MercadoPagoLoading());
      final result = await _repo.crearPreferenciaPago(data);
      await cargarHistorial();
      return result;
    } catch (e) {
      emit(MercadoPagoError('Error al crear preferencia: $e'));
      rethrow;
    }
  }

  /// Actualizar un pago existente
  Future<void> actualizarPago(int pagoId, Map<String, dynamic> datos) async {
    try {
      emit(const MercadoPagoLoading());
      await _repo.actualizarPago(pagoId, datos);
      await cargarHistorial();
    } catch (e) {
      emit(MercadoPagoError('Error al actualizar pago: $e'));
      rethrow;
    }
  }

  /// Verificar el estado de un pago
  Future<Map<String, dynamic>> verificarPago(int pagoId) async {
    try {
      return await _repo.verificarPago(pagoId);
    } catch (e) {
      emit(MercadoPagoError('Error al verificar pago: $e'));
      rethrow;
    }
  }

  /// Obtener detalle de un pago
  Future<Map<String, dynamic>> obtenerDetalle(int pagoId) async {
    try {
      return await _repo.obtenerDetallePago(pagoId);
    } catch (e) {
      emit(MercadoPagoError('Error al obtener detalle: $e'));
      rethrow;
    }
  }

  /// Reembolsar un pago
  Future<void> reembolsarPago(int pagoId) async {
    try {
      await _repo.reembolsarPago(pagoId: pagoId);
      await cargarHistorial();
    } catch (e) {
      emit(MercadoPagoError('Error al reembolsar pago: $e'));
    }
  }

  /// 🔍 Filtrar pagos por cliente, estado o concepto
  void filtrarPagos(String query) {
    if (state is! MercadoPagoLoaded) return;

    final actual = state as MercadoPagoLoaded;

    if (query.isEmpty) {
      emit(actual.copyWith(pagosFiltrados: _todosLosPagos));
      return;
    }

    final q = query.toLowerCase();
    final filtrados = _todosLosPagos.where((pago) {
      final cliente = (pago['cliente_nombre'] ?? '').toString().toLowerCase();
      final estado = (pago['estado_pago'] ?? '').toString().toLowerCase();
      final concepto = (pago['concepto'] ?? '').toString().toLowerCase();
      return cliente.contains(q) || estado.contains(q) || concepto.contains(q);
    }).toList();

    emit(actual.copyWith(pagosFiltrados: filtrados));
  }
}
