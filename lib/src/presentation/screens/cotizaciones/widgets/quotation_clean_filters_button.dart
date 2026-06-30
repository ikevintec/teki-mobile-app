import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/providers/quotation/quotation_list_provider.dart';

class QuotationCleanFiltersButton extends ConsumerWidget {
  const QuotationCleanFiltersButton({super.key});

  int _getActiveFiltersCount(QuotationListState state) {
    int count = 0;

    if (state.filtroSerie?.isNotEmpty == true) count++;
    if (state.filtroNumero?.isNotEmpty == true) count++;
    if (state.filtroEstadoCotizacion != null && state.filtroEstadoCotizacion != 'Todos') count++;

    return count;
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(quotationListProvider.notifier).clearAdditionalFilters();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quotationListProvider);
    final activeFiltersCount = _getActiveFiltersCount(state);

    if (activeFiltersCount > 0) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$activeFiltersCount',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _clearFilters(ref),
                  child: const Icon(
                    Icons.cleaning_services_outlined,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
