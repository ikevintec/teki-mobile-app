import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/repositories/currency_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/currency_repository.dart';

/// Provider global de monedas disponibles.
///
/// Se carga una sola vez (bajo demanda con [CurrenciesNotifier.ensureLoaded])
/// y queda cacheado. La vista de caja lo dispara al montarse de forma no
/// bloqueante; el sheet de movimientos lo reintenta si aún no hay monedas.
final currenciesProvider =
    StateNotifierProvider<CurrenciesNotifier, CurrenciesState>((ref) {
  return CurrenciesNotifier(CurrencyRepositoryImpl());
});

class CurrenciesState {
  final List<Currency> currencies;
  final bool isLoading;
  final String? error;

  const CurrenciesState({
    this.currencies = const [],
    this.isLoading = false,
    this.error,
  });

  bool get hasCurrencies => currencies.isNotEmpty;

  CurrenciesState copyWith({
    List<Currency>? currencies,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CurrenciesState(
      currencies: currencies ?? this.currencies,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CurrenciesNotifier extends StateNotifier<CurrenciesState> {
  final CurrencyRepository repository;

  CurrenciesNotifier(this.repository) : super(const CurrenciesState());

  /// Carga las monedas solo si aún no se tienen y no hay una carga en curso.
  /// Pensado para la carga inicial (no bloqueante) al montar la caja.
  Future<void> ensureLoaded() async {
    if (state.hasCurrencies || state.isLoading) return;
    await _load();
  }

  /// Fuerza una nueva carga (usado por el botón "Reintentar" del sheet).
  Future<void> reload() async {
    if (state.isLoading) return;
    await _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await repository.getCurrencies();
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        currencies: list,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
