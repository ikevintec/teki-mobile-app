import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/repositories/quotation_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/quotation_repository.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final quotationListProvider =
    StateNotifierProvider<QuotationListNotifier, QuotationListState>((ref) {
  final QuotationRepository repository = QuotationRepositoryImpl();
  return QuotationListNotifier(repository: repository, ref: ref);
});

class QuotationListNotifier extends StateNotifier<QuotationListState> {
  final QuotationRepository repository;
  final Ref ref;
  QuotationListNotifier({required this.repository, required this.ref})
      : super(QuotationListState.initial());

  Future<void> loadFirstPage({
    required String desde,
    required String hasta,
    String? serie,
    String? numero,
    String? estadoCotizacion,
  }) async {
    state = state.copyWith(
      filtroDesde: desde,
      filtroHasta: hasta,
      filtroRucEmisor: ref.read(sesionProvider).companySelected?.ruc ?? '',
      idPuntoVenta: ref.read(sesionProvider).office?.id ?? 0,
      idVendedor: ref.read(authStateProvider).user?.id ?? 0,
      quotations: [],
      hasMore: true,
      isLoading: true,
      pageNumber: 0,
      filtroSerie: serie,
      filtroNumero: numero,
      filtroEstadoCotizacion: estadoCotizacion,
    );

    try {
      final newQuotations =
          await repository.getQuotations(buildQuotationQueryParams(state));

      state = state.copyWith(
        isLoading: false,
        pageNumber: state.pageNumber + 1,
        quotations: newQuotations,
        hasMore: newQuotations.length == state.perPage && newQuotations.isNotEmpty,
      );
    } catch (e) {
      errorNotification("Error al cargar cotizaciones: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void updateFilters({
    String? serie,
    String? numero,
    String? estadoCotizacion,
  }) {
    state = state.copyWith(
      filtroSerie: serie,
      filtroNumero: numero,
      filtroEstadoCotizacion: estadoCotizacion,
    );
  }

  Future<void> clearAdditionalFilters() async {
    state = state.copyWith(
      filtroSerie: '',
      filtroNumero: '',
      filtroEstadoCotizacion: 'Todos',
    );
    await loadFirstPage(desde: state.filtroDesde, hasta: state.filtroHasta);
  }

  Future<void> fetchMoreQuotations() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newQuotations =
          await repository.getQuotations(buildQuotationQueryParams(state));

      state = state.copyWith(
        isLoading: false,
        pageNumber: state.pageNumber + 1,
        quotations: [...state.quotations, ...newQuotations],
        hasMore: newQuotations.length == state.perPage && newQuotations.isNotEmpty,
      );
    } catch (e) {
      errorNotification("Error al cargar cotizaciones: $e");
      state = state.copyWith(hasMore: false, isLoading: false);
    }
  }
}

class QuotationListState {
  final List<Quotation> quotations;
  final bool isLoading;
  final bool hasMore;
  final int pageNumber;
  final int perPage;
  final int sortOrder;
  final String filtroDesde;
  final String filtroHasta;
  final String filtroRucEmisor;
  final int idPuntoVenta;
  final int idVendedor;
  final String? filtroSerie;
  final String? filtroNumero;
  final String? filtroEstadoCotizacion;

  QuotationListState({
    required this.quotations,
    required this.isLoading,
    required this.hasMore,
    required this.pageNumber,
    required this.perPage,
    required this.sortOrder,
    required this.filtroDesde,
    required this.filtroHasta,
    required this.filtroRucEmisor,
    required this.idPuntoVenta,
    required this.idVendedor,
    this.filtroSerie,
    this.filtroNumero,
    this.filtroEstadoCotizacion,
  });

  factory QuotationListState.initial() => QuotationListState(
        quotations: [],
        isLoading: false,
        hasMore: true,
        pageNumber: 0,
        perPage: 10,
        sortOrder: 1,
        filtroDesde: '',
        filtroHasta: '',
        filtroRucEmisor: '',
        idPuntoVenta: 0,
        idVendedor: 0,
        filtroSerie: null,
        filtroNumero: null,
        filtroEstadoCotizacion: null,
      );

  QuotationListState copyWith({
    List<Quotation>? quotations,
    bool? isLoading,
    bool? hasMore,
    int? pageNumber,
    int? perPage,
    int? sortOrder,
    String? filtroDesde,
    String? filtroHasta,
    String? filtroRucEmisor,
    int? idPuntoVenta,
    int? idVendedor,
    String? filtroSerie,
    String? filtroNumero,
    String? filtroEstadoCotizacion,
  }) {
    return QuotationListState(
      quotations: quotations ?? this.quotations,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      pageNumber: pageNumber ?? this.pageNumber,
      perPage: perPage ?? this.perPage,
      sortOrder: sortOrder ?? this.sortOrder,
      filtroDesde: filtroDesde ?? this.filtroDesde,
      filtroHasta: filtroHasta ?? this.filtroHasta,
      filtroRucEmisor: filtroRucEmisor ?? this.filtroRucEmisor,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      idVendedor: idVendedor ?? this.idVendedor,
      filtroSerie: filtroSerie ?? this.filtroSerie,
      filtroNumero: filtroNumero ?? this.filtroNumero,
      filtroEstadoCotizacion: filtroEstadoCotizacion ?? this.filtroEstadoCotizacion,
    );
  }
}
