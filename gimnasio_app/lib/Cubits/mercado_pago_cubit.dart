import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimnasio_app/repositorio_api/mercado_pago_repositorio.dart';

part 'mercado_pago_state.dart';

class MercadoPagoCubit extends Cubit<MercadoPagoState> {
  final MercadoPagoRepository _repository;

  MercadoPagoCubit({required MercadoPagoRepository repository})
      : _repository = repository,
        super(MercadoPagoInitial());

  Future<void> cargarHistorial({
    String? estado,
    String? clienteDni,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      emit(MercadoPagoLoading());
      final lista = await _repository.obtenerHistorialPagos(
        estado: estado,
        clienteDni: clienteDni,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      final pagos = List<Map<String, dynamic>>.from(lista);
      emit(MercadoPagoLoaded(pagos: pagos, pagosFiltrados: pagos));
    } catch (e) {
      emit(MercadoPagoError(message: e.toString()));
    }
  }

  Future<void> crearPago(Map<String, dynamic> datos) async {
    try {
      emit(MercadoPagoLoading());
      final pago = await _repository.crearPago(datos);
      if (state is MercadoPagoLoaded) {
        final current = state as MercadoPagoLoaded;
        final nuevos = [...current.pagos, Map<String, dynamic>.from(pago)];
        emit(current.copyWith(pagos: nuevos, pagosFiltrados: nuevos));
      } else {
        await cargarHistorial();
      }
    } catch (e) {
      emit(MercadoPagoError(message: e.toString()));
    }
  }

  /// Crea una preferencia de pago (usualmente retorna init_point / preference)
  Future<Map<String, dynamic>> crearPreferencia(
      Map<String, dynamic> datos) async {
    try {
      final res = await _repository.crearPreferenciaPago(datos);
      return res;
    } catch (e) {
      throw Exception('Error creando preferencia: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> actualizarPago(
      int pagoId, Map<String, dynamic> datos) async {
    try {
      emit(MercadoPagoLoading());
      final res = await _repository.actualizarPago(pagoId, datos);
      await cargarHistorial();
      return res;
    } catch (e) {
      emit(MercadoPagoError(message: e.toString()));
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> verificarPago(int pagoId) async {
    try {
      final res = await _repository.verificarPago(pagoId);
      return res;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> reembolsarPago(int pagoId, {double? monto}) async {
    try {
      emit(MercadoPagoLoading());
      await _repository.reembolsarPago(pagoId: pagoId, monto: monto);
      await cargarHistorial();
    } catch (e) {
      emit(MercadoPagoError(message: e.toString()));
    }
  }

  Future<Map<String, dynamic>> obtenerDetalle(int pagoId) async {
    try {
      final detalle = await _repository.obtenerDetallePago(pagoId);
      return detalle;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
