import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/cash_register_repository.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_detail_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';

final cashRegisterProvider =
    StateNotifierProvider<CashRegisterNotifier, CashRegisterState>((ref) {
  return CashRegisterNotifier(
    ref: ref,
    repository: CashRegisterRepositoryImpl(),
  );
});

class CashRegisterNotifier extends StateNotifier<CashRegisterState> {
  final Ref ref;
  final CashRegisterRepository repository;
  CancelToken? _cancelToken;

  CashRegisterNotifier({required this.ref, required this.repository})
      : super(const CashRegisterState());

  /// Carga la caja del punto de venta/estación de la sesión para [fecha]
  /// (null = hoy) y luego el historial de la moneda activa; si no hay
  /// registros, limpia el historial. En paralelo refresca la detección de
  /// caja abierta (sin filtro de fecha) para el aviso de caja pendiente.
  Future<void> fetchAndLoadDetail({
    String? selectedMoneda,
    DateTime? fecha,
  }) async {
    final sesion = ref.read(sesionProvider);
    final idPV = sesion.office?.id ?? 0;
    final idEV = sesion.saleStation?.id ?? 0;

    // No bloquea la carga principal; el datasource devuelve [] ante errores.
    final openFuture = repository.getOpenCashRegisters(
      idPuntoVenta: idPV,
      idEstacionVenta: idEV,
    );

    await fetch(
      idPuntoVenta: idPV,
      idEstacionVenta: idEV,
      fecha: fecha != null ? DateFormat('dd-MM-yyyy').format(fecha) : null,
    );
    if (!mounted) return;
    if (state.registers.isEmpty) {
      ref.read(cashRegisterDetailProvider.notifier).clear();
    } else {
      loadDetail(selectedMoneda: selectedMoneda);
    }

    final abiertas = await openFuture;
    if (!mounted) return;
    state = state.copyWith(openRegister: _masReciente(abiertas));
  }

  /// La caja abierta con fecha más reciente (o la primera sin fecha).
  CashRegisterResponse? _masReciente(List<CashRegisterResponse> abiertas) {
    if (abiertas.isEmpty) return null;
    final ordenadas = [...abiertas]..sort((a, b) {
        final fa = a.fecha, fb = b.fecha;
        if (fa == null && fb == null) return 0;
        if (fa == null) return 1;
        if (fb == null) return -1;
        return fb.compareTo(fa);
      });
    return ordenadas.first;
  }

  /// Dispara la carga del historial usando el primer registro disponible y
  /// la moneda activa según [selectedMoneda].
  void loadDetail({String? selectedMoneda}) {
    if (state.registers.isEmpty) return;
    final idCaja = state.registers.first.id;
    if (idCaja == null) return;

    ref.read(cashRegisterDetailProvider.notifier).load(
          idCaja: idCaja,
          moneda: state.monedaActiva(selectedMoneda),
        );
  }

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
  static const _unset = Object();

  final bool isLoading;
  final List<CashRegisterResponse> registers;
  final String? error;

  /// Caja en estado APERTURADA más reciente del punto de venta/estación,
  /// sin filtro de fecha. Null cuando no hay ninguna abierta.
  final CashRegisterResponse? openRegister;

  const CashRegisterState({
    this.isLoading = false,
    this.registers = const [],
    this.error,
    this.openRegister,
  });

  /// True si hay una caja abierta cuya fecha operativa NO es [fecha]
  /// (candidata al aviso de "tienes una caja abierta de otro día").
  bool openRegisterEsOtraFecha(DateTime fecha) {
    final f = openRegister?.fecha;
    if (f == null) return false;
    return f.year != fecha.year || f.month != fecha.month || f.day != fecha.day;
  }

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

  /// Monedas con movimientos, con PEN siempre primero.
  List<String> get monedas =>
      {...balancePorMoneda.keys}.toList()..sort((a, b) => a == 'PEN' ? -1 : 1);

  /// Moneda a mostrar: la seleccionada si sigue disponible; si no, PEN;
  /// si tampoco hay PEN, la primera disponible (o PEN por defecto).
  String monedaActiva(String? seleccionada) {
    final disponibles = monedas;
    if (seleccionada != null && disponibles.contains(seleccionada)) {
      return seleccionada;
    }
    if (disponibles.contains('PEN')) return 'PEN';
    return disponibles.isNotEmpty ? disponibles.first : 'PEN';
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
    Object? openRegister = _unset,
  }) {
    return CashRegisterState(
      isLoading: isLoading ?? this.isLoading,
      registers: registers ?? this.registers,
      error: error,
      openRegister: identical(openRegister, _unset)
          ? this.openRegister
          : openRegister as CashRegisterResponse?,
    );
  }
}
