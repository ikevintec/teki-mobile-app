import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/response/accounts_receivable_total_response.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivable.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/repositories/accounts_receivable_repository_impl.dart';
import 'package:teki_app/src/data/repositories/currency_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/accounts_receivable_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final accountsReceivableProvider = StateNotifierProvider.family<
    AccountsReceivableNotifier, AccountsReceivableState, String>(
  (ref, tipoCuenta) {
    final repo = AccountsReceivableRepositoryImpl();
    return AccountsReceivableNotifier(
      repository: repo,
      ref: ref,
      tipoCuenta: tipoCuenta,
    );
  },
);

class AccountsReceivableNotifier extends StateNotifier<AccountsReceivableState> {
  final AccountsReceivableRepository repository;
  final Ref ref;

  bool _currenciesLoaded = false;
  bool _idPuntoVentaInitialized = false;

  AccountsReceivableNotifier({
    required this.repository,
    required this.ref,
    required String tipoCuenta,
  }) : super(AccountsReceivableState.initial(tipoCuenta));

  Future<void> _ensureCurrenciesLoaded() async {
    if (_currenciesLoaded) return;
    _currenciesLoaded = true;
    try {
      final currencies = await CurrencyRepositoryImpl().getCurrencies();
      state = state.copyWith(currencies: currencies);
    } catch (e) {
      _currenciesLoaded = false;
      errorNotification('Error al obtener monedas: $e');
    }
  }

  /// Carga (o recarga) la primera página respetando los filtros ya aplicados en el state.
  /// Se usa tanto al entrar a la pantalla, como al aplicar cualquier filtro,
  /// como al hacer pull-to-refresh: siempre vuelve a pageNumber 0.
  Future<void> loadFirstPage() async {
    if (!_idPuntoVentaInitialized) {
      _idPuntoVentaInitialized = true;
      final defaultPuntoVenta = ref.read(sesionProvider).office?.id;
      if (defaultPuntoVenta != null) {
        state = state.copyWith(idPuntoVenta: defaultPuntoVenta);
      }
    }

    await _ensureCurrenciesLoaded();

    state = state.copyWith(
      isLoading: true,
      pageNumber: 0,
      accounts: [],
      hasMore: true,
    );

    try {
      final params = buildAccountsReceivableQueryParams(state);
      final accounts = await repository.getAccounts(params);
      state = state.copyWith(
        accounts: accounts,
        isLoading: false,
        pageNumber: state.pageNumber + 1,
        hasMore: accounts.length == state.perPage && accounts.isNotEmpty,
      );
      await _loadTotales();
    } catch (e) {
      errorNotification('Error al cargar cuentas: $e');
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final params = buildAccountsReceivableQueryParams(state);
      final newAccounts = await repository.getAccounts(params);
      state = state.copyWith(
        accounts: [...state.accounts, ...newAccounts],
        isLoading: false,
        pageNumber: state.pageNumber + 1,
        hasMore: newAccounts.length == state.perPage && newAccounts.isNotEmpty,
      );
    } catch (e) {
      errorNotification('Error al cargar más cuentas: $e');
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  Future<void> _loadTotales() async {
    try {
      final params = buildAccountsReceivableQueryParams(state);
      final totales = await repository.getTotales(params, state.currencies);
      state = state.copyWith(totales: totales);
    } catch (e) {
      errorNotification('Error al obtener totales: $e');
    }
  }

  /// Aplica los filtros de fecha (emisión/vencimiento) y recarga desde la página 0.
  /// Solo se invoca cuando el usuario presiona "Aplicar" en el modal de fechas.
  Future<void> applyDateFilters({
    String? filtroEmisionDesde,
    String? filtroEmisionHasta,
    String? filtroVencimientoDesde,
    String? filtroVencimientoHasta,
  }) async {
    state = state.withDateFilters(
      filtroEmisionDesde: filtroEmisionDesde,
      filtroEmisionHasta: filtroEmisionHasta,
      filtroVencimientoDesde: filtroVencimientoDesde,
      filtroVencimientoHasta: filtroVencimientoHasta,
    );
    await loadFirstPage();
  }

  /// Aplica el resto de filtros y recarga desde la página 0.
  /// Solo se invoca cuando el usuario presiona "Aplicar" en el modal de otros filtros.
  Future<void> applyOtherFilters({
    List<String>? tipoComprobante,
    String? numero,
    String? serie,
    String? cliente,
    String? comprobante,
    String? diasCredito,
    List<String>? estadoCredito,
    int? idVendedor,
    int? idPuntoVenta,
  }) async {
    state = state.withOtherFilters(
      tipoComprobante: tipoComprobante,
      numero: numero,
      serie: serie,
      cliente: cliente,
      comprobante: comprobante,
      diasCredito: diasCredito,
      estadoCredito: estadoCredito,
      idVendedor: idVendedor,
      idPuntoVenta: idPuntoVenta,
    );
    await loadFirstPage();
  }
}

class AccountsReceivableState {
  final String tipoCuenta;
  final List<AccountsReceivable> accounts;
  final bool isLoading;
  final bool hasMore;
  final int pageNumber;
  final int perPage;

  final List<Currency> currencies;
  final List<AccountsReceivableTotalResponse> totales;

  // Punto de venta efectivo: null significa "Todos" (no se envía el parámetro)
  final int? idPuntoVenta;
  final int? idVendedor;

  final String? filtroEmisionDesde;
  final String? filtroEmisionHasta;
  final String? filtroVencimientoDesde;
  final String? filtroVencimientoHasta;

  final List<String>? tipoComprobante;
  final String? numero;
  final String? serie;
  final String? cliente;
  final String? comprobante;
  final String? diasCredito;
  final List<String>? estadoCredito;

  AccountsReceivableState({
    required this.tipoCuenta,
    required this.accounts,
    required this.isLoading,
    required this.hasMore,
    required this.pageNumber,
    required this.perPage,
    required this.currencies,
    required this.totales,
    this.idPuntoVenta,
    this.idVendedor,
    this.filtroEmisionDesde,
    this.filtroEmisionHasta,
    this.filtroVencimientoDesde,
    this.filtroVencimientoHasta,
    this.tipoComprobante,
    this.numero,
    this.serie,
    this.cliente,
    this.comprobante,
    this.diasCredito,
    this.estadoCredito,
  });

  factory AccountsReceivableState.initial(String tipoCuenta) =>
      AccountsReceivableState(
        tipoCuenta: tipoCuenta,
        accounts: [],
        isLoading: false,
        hasMore: true,
        pageNumber: 0,
        perPage: 10,
        currencies: [],
        totales: [],
      );

  /// Copia estándar para campos de paginación/carga/datos, nunca usado para
  /// limpiar (poner en null) un filtro ya aplicado.
  AccountsReceivableState copyWith({
    List<AccountsReceivable>? accounts,
    bool? isLoading,
    bool? hasMore,
    int? pageNumber,
    int? perPage,
    List<Currency>? currencies,
    List<AccountsReceivableTotalResponse>? totales,
    int? idPuntoVenta,
  }) {
    return AccountsReceivableState(
      tipoCuenta: tipoCuenta,
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      pageNumber: pageNumber ?? this.pageNumber,
      perPage: perPage ?? this.perPage,
      currencies: currencies ?? this.currencies,
      totales: totales ?? this.totales,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      idVendedor: idVendedor,
      filtroEmisionDesde: filtroEmisionDesde,
      filtroEmisionHasta: filtroEmisionHasta,
      filtroVencimientoDesde: filtroVencimientoDesde,
      filtroVencimientoHasta: filtroVencimientoHasta,
      tipoComprobante: tipoComprobante,
      numero: numero,
      serie: serie,
      cliente: cliente,
      comprobante: comprobante,
      diasCredito: diasCredito,
      estadoCredito: estadoCredito,
    );
  }

  /// Reemplaza explícitamente los filtros de fecha (permite limpiarlos a null).
  AccountsReceivableState withDateFilters({
    required String? filtroEmisionDesde,
    required String? filtroEmisionHasta,
    required String? filtroVencimientoDesde,
    required String? filtroVencimientoHasta,
  }) {
    return AccountsReceivableState(
      tipoCuenta: tipoCuenta,
      accounts: accounts,
      isLoading: isLoading,
      hasMore: hasMore,
      pageNumber: pageNumber,
      perPage: perPage,
      currencies: currencies,
      totales: totales,
      idPuntoVenta: idPuntoVenta,
      idVendedor: idVendedor,
      filtroEmisionDesde: filtroEmisionDesde,
      filtroEmisionHasta: filtroEmisionHasta,
      filtroVencimientoDesde: filtroVencimientoDesde,
      filtroVencimientoHasta: filtroVencimientoHasta,
      tipoComprobante: tipoComprobante,
      numero: numero,
      serie: serie,
      cliente: cliente,
      comprobante: comprobante,
      diasCredito: diasCredito,
      estadoCredito: estadoCredito,
    );
  }

  /// Reemplaza explícitamente el resto de filtros (permite limpiarlos a null,
  /// incluyendo volver idPuntoVenta a "Todos").
  AccountsReceivableState withOtherFilters({
    required List<String>? tipoComprobante,
    required String? numero,
    required String? serie,
    required String? cliente,
    required String? comprobante,
    required String? diasCredito,
    required List<String>? estadoCredito,
    required int? idVendedor,
    required int? idPuntoVenta,
  }) {
    return AccountsReceivableState(
      tipoCuenta: tipoCuenta,
      accounts: accounts,
      isLoading: isLoading,
      hasMore: hasMore,
      pageNumber: pageNumber,
      perPage: perPage,
      currencies: currencies,
      totales: totales,
      idPuntoVenta: idPuntoVenta,
      idVendedor: idVendedor,
      filtroEmisionDesde: filtroEmisionDesde,
      filtroEmisionHasta: filtroEmisionHasta,
      filtroVencimientoDesde: filtroVencimientoDesde,
      filtroVencimientoHasta: filtroVencimientoHasta,
      tipoComprobante: tipoComprobante,
      numero: numero,
      serie: serie,
      cliente: cliente,
      comprobante: comprobante,
      diasCredito: diasCredito,
      estadoCredito: estadoCredito,
    );
  }
}
