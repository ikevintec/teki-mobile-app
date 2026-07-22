import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/cash_register_repository.dart';

final cashRegisterDetailProvider = StateNotifierProvider<
    CashRegisterDetailNotifier, CashRegisterDetailState>((ref) {
  return CashRegisterDetailNotifier(
    repository: CashRegisterRepositoryImpl(),
  );
});

class CashRegisterDetailNotifier
    extends StateNotifier<CashRegisterDetailState> {
  final CashRegisterRepository repository;
  CancelToken? _cancelToken;

  CashRegisterDetailNotifier({required this.repository})
      : super(const CashRegisterDetailState());

  /// Carga inicial o reset completo (página 0).
  Future<void> load({
    required int idCaja,
    String tipo = 'INGRESO',
    required String moneda,
  }) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      items: [],
      page: 0,
      hasMore: true,
      tipo: tipo,
      moneda: moneda,
      idCaja: idCaja,
      clearError: true,
    );

    try {
      final page = await repository.getCashRegisterDetail(
        idCaja: idCaja,
        tipo: tipo,
        moneda: moneda,
        page: 0,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      final items =
          page.rawItems.map(CashRegisterDetail.fromJson).toList();
      state = state.copyWith(
        isLoading: false,
        items: items,
        hasMore: !page.isLast,
        page: 0,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Carga la siguiente página (scroll infinito).
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.idCaja == null) return;

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final page = await repository.getCashRegisterDetail(
        idCaja: state.idCaja!,
        tipo: state.tipo,
        moneda: state.moneda,
        page: nextPage,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      final newItems =
          page.rawItems.map(CashRegisterDetail.fromJson).toList();
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...newItems],
        hasMore: !page.isLast,
        page: nextPage,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Cambia entre INGRESO / EGRESO. Bloqueado mientras haya carga en curso.
  Future<void> changeTipo(String newTipo) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.idCaja == null) return;
    await load(idCaja: state.idCaja!, tipo: newTipo, moneda: state.moneda);
  }

  /// Cambia la moneda y reinicia la paginación desde la página 0.
  Future<void> changeMoneda(String newMoneda) async {
    if (state.idCaja == null) return;
    await load(idCaja: state.idCaja!, tipo: state.tipo, moneda: newMoneda);
  }

  void clear() {
    state = CashRegisterDetailState();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}

class CashRegisterDetailState {
  final List<CashRegisterDetail> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String tipo;
  final String moneda;
  final int? idCaja;
  final String? error;

  const CashRegisterDetailState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.tipo = 'INGRESO',
    this.moneda = 'PEN',
    this.idCaja,
    this.error,
  });

  CashRegisterDetailState copyWith({
    List<CashRegisterDetail>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? tipo,
    String? moneda,
    int? idCaja,
    String? error,
    bool clearError = false,
  }) {
    return CashRegisterDetailState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      tipo: tipo ?? this.tipo,
      moneda: moneda ?? this.moneda,
      idCaja: idCaja ?? this.idCaja,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
