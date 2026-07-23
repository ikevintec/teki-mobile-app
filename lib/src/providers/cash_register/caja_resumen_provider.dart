import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/response/caja_resumen.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/cash_register_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Resumen de caja por rango (modo reporte)
// ─────────────────────────────────────────────────────────────────────────────

final cajaResumenProvider =
    StateNotifierProvider<CajaResumenNotifier, CajaResumenState>((ref) {
  return CajaResumenNotifier(
    ref: ref,
    repository: CashRegisterRepositoryImpl(),
  );
});

class CajaResumenNotifier extends StateNotifier<CajaResumenState> {
  final Ref ref;
  final CashRegisterRepository repository;
  int _requestId = 0;

  CajaResumenNotifier({required this.ref, required this.repository})
      : super(const CajaResumenState());

  Future<void> fetch(DateTimeRange range) async {
    final requestId = ++_requestId;
    final sesion = ref.read(sesionProvider);
    state = state.copyWith(isLoading: true, error: null, range: range);
    try {
      final fmt = DateFormat('dd-MM-yyyy');
      final resumen = await repository.getResumen(
        desde: fmt.format(range.start),
        hasta: fmt.format(range.end),
        idPuntoVenta: sesion.office?.id,
        idEstacionVenta: sesion.saleStation?.id,
      );
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, resumen: resumen);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class CajaResumenState {
  final bool isLoading;
  final String? error;
  final CajaResumen? resumen;
  final DateTimeRange? range;

  const CajaResumenState({
    this.isLoading = false,
    this.error,
    this.resumen,
    this.range,
  });

  CajaResumenState copyWith({
    bool? isLoading,
    String? error,
    CajaResumen? resumen,
    DateTimeRange? range,
  }) {
    return CajaResumenState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      resumen: resumen ?? this.resumen,
      range: range ?? this.range,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Movimientos del rango, paginados (drill-down del modo reporte)
// ─────────────────────────────────────────────────────────────────────────────

final rangoMovimientosProvider =
    StateNotifierProvider<RangoMovimientosNotifier, RangoMovimientosState>(
        (ref) {
  return RangoMovimientosNotifier(
    ref: ref,
    repository: CashRegisterRepositoryImpl(),
  );
});

class RangoMovimientosNotifier extends StateNotifier<RangoMovimientosState> {
  static const _perPage = 20;

  final Ref ref;
  final CashRegisterRepository repository;
  int _requestId = 0;

  RangoMovimientosNotifier({required this.ref, required this.repository})
      : super(const RangoMovimientosState());

  Future<void> load(DateTimeRange range, {String? tipo}) async {
    final requestId = ++_requestId;
    state = RangoMovimientosState(isLoading: true, range: range, tipo: tipo);
    final page = await _fetchPage(range, tipo, 0);
    if (!mounted || requestId != _requestId || page == null) return;
    state = state.copyWith(
      isLoading: false,
      items: page.items,
      pageNumber: 0,
      isLast: page.isLast,
    );
  }

  Future<void> loadMore() async {
    final range = state.range;
    if (range == null || state.isLast || state.isLoading || state.isLoadingMore) {
      return;
    }
    final requestId = _requestId;
    state = state.copyWith(isLoadingMore: true);
    final page = await _fetchPage(range, state.tipo, state.pageNumber + 1);
    if (!mounted || requestId != _requestId || page == null) {
      if (mounted && requestId == _requestId) {
        state = state.copyWith(isLoadingMore: false);
      }
      return;
    }
    state = state.copyWith(
      isLoadingMore: false,
      items: [...state.items, ...page.items],
      pageNumber: state.pageNumber + 1,
      isLast: page.isLast,
    );
  }

  Future<({List<CashRegisterDetail> items, bool isLast})?> _fetchPage(
      DateTimeRange range, String? tipo, int pageNumber) async {
    try {
      final sesion = ref.read(sesionProvider);
      final fmt = DateFormat('dd-MM-yyyy');
      final page = await repository.getMovimientosRango(
        desde: fmt.format(range.start),
        hasta: fmt.format(range.end),
        idPuntoVenta: sesion.office?.id,
        idEstacionVenta: sesion.saleStation?.id,
        tipo: tipo,
        page: pageNumber,
        perPage: _perPage,
      );
      return (
        items: page.rawItems.map(CashRegisterDetail.fromJson).toList(),
        isLast: page.isLast,
      );
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

class RangoMovimientosState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<CashRegisterDetail> items;
  final int pageNumber;
  final bool isLast;
  final DateTimeRange? range;

  /// Filtro de tipo: 'INGRESO', 'EGRESO' o null (todos).
  final String? tipo;

  const RangoMovimientosState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.items = const [],
    this.pageNumber = 0,
    this.isLast = false,
    this.range,
    this.tipo,
  });

  RangoMovimientosState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<CashRegisterDetail>? items,
    int? pageNumber,
    bool? isLast,
    DateTimeRange? range,
    String? tipo,
  }) {
    return RangoMovimientosState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      items: items ?? this.items,
      pageNumber: pageNumber ?? this.pageNumber,
      isLast: isLast ?? this.isLast,
      range: range ?? this.range,
      tipo: tipo ?? this.tipo,
    );
  }
}
