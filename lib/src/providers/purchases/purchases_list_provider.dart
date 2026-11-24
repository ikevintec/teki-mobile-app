import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/repositories/purchases_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/purchases_repository.dart';

class PurchasesListState {
  final List<Purchase> purchases;
  final bool loading;
  final int page;
  final bool hasMore;

  /// Mes filtrado (1..12) y año; por defecto el mes actual, como la web.
  final int mes;
  final int anio;
  final String search;

  const PurchasesListState({
    this.purchases = const [],
    this.loading = false,
    this.page = 0,
    this.hasMore = true,
    required this.mes,
    required this.anio,
    this.search = '',
  });

  PurchasesListState copyWith({
    List<Purchase>? purchases,
    bool? loading,
    int? page,
    bool? hasMore,
    int? mes,
    int? anio,
    String? search,
  }) =>
      PurchasesListState(
        purchases: purchases ?? this.purchases,
        loading: loading ?? this.loading,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        mes: mes ?? this.mes,
        anio: anio ?? this.anio,
        search: search ?? this.search,
      );
}

class PurchasesListNotifier extends StateNotifier<PurchasesListState> {
  final PurchasesRepository _repo;
  static const _perPage = 15;
  int _loadSeq = 0;

  PurchasesListNotifier(this._repo)
      : super(PurchasesListState(
            mes: DateTime.now().month, anio: DateTime.now().year));

  Map<String, dynamic> _params(int page) {
    final fmt = DateFormat('dd-MM-yyyy');
    final desde = DateTime(state.anio, state.mes, 1);
    final hasta = DateTime(state.anio, state.mes + 1, 0);
    return {
      'paginacion': 'true',
      'tipoOperacion': 'COMPRA',
      'pageNumber': '$page',
      'perPage': '$_perPage',
      'sortField': 'fecha',
      'sortOrder': '0',
      'desde': fmt.format(desde),
      'hasta': fmt.format(hasta),
      // El backend filtra por número de comprobante con `comprobante`.
      if (state.search.trim().isNotEmpty) 'comprobante': state.search.trim(),
    };
  }

  Future<void> loadFirstPage() async {
    final seq = ++_loadSeq;
    state = state.copyWith(loading: true, page: 0);
    try {
      final res = await _repo.getPurchases(_params(0));
      if (seq != _loadSeq) return; // respuesta vieja
      state = state.copyWith(
        purchases: res.content,
        loading: false,
        hasMore: !res.last,
      );
    } catch (_) {
      if (seq == _loadSeq) state = state.copyWith(loading: false);
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final seq = ++_loadSeq;
    final next = state.page + 1;
    state = state.copyWith(loading: true);
    try {
      final res = await _repo.getPurchases(_params(next));
      if (seq != _loadSeq) return;
      state = state.copyWith(
        purchases: [...state.purchases, ...res.content],
        loading: false,
        page: next,
        hasMore: !res.last,
      );
    } catch (_) {
      if (seq == _loadSeq) state = state.copyWith(loading: false);
    }
  }

  Future<void> setMes(int mes, int anio) async {
    state = state.copyWith(mes: mes, anio: anio);
    await loadFirstPage();
  }

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value);
    await loadFirstPage();
  }

  Future<void> refresh() => loadFirstPage();

  Future<void> cancel(int id, String motivo) async {
    await _repo.cancelPurchase(id, motivo);
    await loadFirstPage();
  }
}

final purchasesListProvider =
    StateNotifierProvider<PurchasesListNotifier, PurchasesListState>(
        (ref) => PurchasesListNotifier(PurchasesRepositoryImpl()));
