import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/caja_metodo_pago_balance.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/cash_register_repository.dart';

final cashRegisterBalanceProvider = StateNotifierProvider.family<
    CashRegisterBalanceNotifier, CashRegisterBalanceState, int>(
  (ref, idCaja) => CashRegisterBalanceNotifier(
    idCaja: idCaja,
    repository: CashRegisterRepositoryImpl(),
  ),
);

class CashRegisterBalanceNotifier
    extends StateNotifier<CashRegisterBalanceState> {
  final int idCaja;
  final CashRegisterRepository repository;
  CancelToken? _cancelToken;

  CashRegisterBalanceNotifier({
    required this.idCaja,
    required this.repository,
  }) : super(const CashRegisterBalanceState());

  Future<void> fetch() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final items = await repository.getTotalesMetodoPago(
        idCaja: idCaja,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false, items: items);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}

class CashRegisterBalanceState {
  final bool isLoading;
  final List<CajaMetodoPagoBalance> items;
  final String? error;

  const CashRegisterBalanceState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  List<String> get monedas {
    final set = <String>{};
    for (final item in items) {
      for (final m in item.ingreso) {
        set.add(m.moneda);
      }
      for (final m in item.egreso) {
        set.add(m.moneda);
      }
    }
    return set.toList()..sort((a, b) => a == 'PEN' ? -1 : 1);
  }

  double totalIngresoForMoneda(String moneda) => items.fold(
        0.0,
        (acc, item) => acc + item.ingresoForMoneda(moneda),
      );

  double totalEgresoForMoneda(String moneda) => items.fold(
        0.0,
        (acc, item) => acc + item.egresoForMoneda(moneda),
      );

  double totalGananciaForMoneda(String moneda) =>
      totalIngresoForMoneda(moneda) - totalEgresoForMoneda(moneda);

  CashRegisterBalanceState copyWith({
    bool? isLoading,
    List<CajaMetodoPagoBalance>? items,
    String? error,
    bool clearError = false,
  }) {
    return CashRegisterBalanceState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
