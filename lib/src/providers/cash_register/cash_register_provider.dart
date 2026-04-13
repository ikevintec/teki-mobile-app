import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/cash_register_repository.dart';

final cashRegisterProvider =
    StateNotifierProvider<CashRegisterNotifier, CashRegisterState>((ref) {
  return CashRegisterNotifier(
    repository: CashRegisterRepositoryImpl(),
  );
});

class CashRegisterNotifier extends StateNotifier<CashRegisterState> {
  final CashRegisterRepository repository;
  CancelToken? _cancelToken;

  CashRegisterNotifier({required this.repository})
      : super(const CashRegisterState());

  Future<void> fetch({
    required int idPuntoVenta,
    required int idEstacionVenta,
    String? fecha, // null = hoy, formato: dd-MM-yyyy
  }) async {
    // Cancela cualquier petición en vuelo antes de lanzar una nueva
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(isLoading: true, error: null);

    try {
      final fechaStr = fecha ?? DateFormat('dd-MM-yyyy').format(DateTime.now());
      final registers = await repository.getCashRegister(
        idPuntoVenta: idPuntoVenta,
        idEstacionVenta: idEstacionVenta,
        fecha: fechaStr,
        cancelToken: _cancelToken,
      );

      if (!mounted) return;
      state = state.copyWith(isLoading: false, registers: registers);
    } on DioException catch (e) {
      // Petición cancelada → ignorar silenciosamente, no alterar estado visible
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

class CashRegisterState {
  final bool isLoading;
  final List<CashRegisterResponse> registers;
  final String? error;

  const CashRegisterState({
    this.isLoading = false,
    this.registers = const [],
    this.error,
  });

  /// Suma de ingresos agrupados por moneda (considerando todos los registros del día)
  Map<String, double> get totalIngresosPorMoneda {
    final totals = <String, double>{};
    for (final r in registers) {
      for (final m in r.montosTotalesIngresos) {
        totals[m.moneda] = (totals[m.moneda] ?? 0) + m.monto;
      }
    }
    return totals;
  }

  /// Suma de egresos agrupados por moneda
  Map<String, double> get totalEgresosPorMoneda {
    final totals = <String, double>{};
    for (final r in registers) {
      for (final m in r.montosTotalesEgresos) {
        totals[m.moneda] = (totals[m.moneda] ?? 0) + m.monto;
      }
    }
    return totals;
  }

  /// Efectivo en caja agrupado por moneda
  Map<String, double> get totalEfectivoPorMoneda {
    final totals = <String, double>{};
    for (final r in registers) {
      for (final m in r.montosIngresosEfectivo) {
        totals[m.moneda] = (totals[m.moneda] ?? 0) + m.monto;
      }
    }
    return totals;
  }

  /// Balance neto por moneda
  Map<String, double> get balancePorMoneda {
    final ingresos = totalIngresosPorMoneda;
    final egresos = totalEgresosPorMoneda;
    final monedas = {...ingresos.keys, ...egresos.keys};
    return {
      for (final m in monedas)
        m: (ingresos[m] ?? 0) - (egresos[m] ?? 0),
    };
  }

  CashRegisterState copyWith({
    bool? isLoading,
    List<CashRegisterResponse>? registers,
    String? error,
  }) {
    return CashRegisterState(
      isLoading: isLoading ?? this.isLoading,
      registers: registers ?? this.registers,
      error: error,
    );
  }
}
