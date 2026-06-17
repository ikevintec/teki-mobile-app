import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/repositories/quotation_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/quotation_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

final quotationViewProvider =
    StateNotifierProvider<QuotationViewNotifier, QuotationViewState>((ref) {
  final QuotationRepository repository = QuotationRepositoryImpl();
  return QuotationViewNotifier(repository: repository);
});

class QuotationViewNotifier extends StateNotifier<QuotationViewState> {
  final QuotationRepository repository;

  QuotationViewNotifier({required this.repository})
      : super(QuotationViewState.initial());

  Future<void> fetchQuotationById(int id) async {
    state = state.copyWith(isLoading: true, id: id);
    try {
      final quotation = await repository.getQuotationById(id);
      state = state.copyWith(quotation: quotation, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      errorNotification("Error al cargar la cotización: $e");
    }
  }

  void clearState() {
    state = QuotationViewState.initial();
  }
}

class QuotationViewState {
  final int id;
  final Quotation quotation;
  final bool isLoading;

  QuotationViewState({
    required this.id,
    required this.quotation,
    required this.isLoading,
  });

  factory QuotationViewState.initial() {
    return QuotationViewState(
      id: 0,
      quotation: Quotation(),
      isLoading: false,
    );
  }

  QuotationViewState copyWith({
    int? id,
    Quotation? quotation,
    bool? isLoading,
  }) {
    return QuotationViewState(
      id: id ?? this.id,
      quotation: quotation ?? this.quotation,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
