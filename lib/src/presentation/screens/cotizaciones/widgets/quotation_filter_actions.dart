import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/widgets/quotation_other_filters.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/quotation/quotation_list_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class QuotationFilterActions extends ConsumerWidget {
  const QuotationFilterActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () {
            showCustomModal(
              context: context,
              child: QuotationOtherFilters(
                onApplyFilters: () {
                  Navigator.pop(context);
                  final currentState = ref.read(quotationListProvider);
                  final desde = currentState.filtroDesde;
                  final hasta = currentState.filtroHasta;

                  if (desde.isNotEmpty && hasta.isNotEmpty) {
                    ref.read(quotationListProvider.notifier).loadFirstPage(
                          desde: desde,
                          hasta: hasta,
                          serie: currentState.filtroSerie,
                          numero: currentState.filtroNumero,
                          estadoCotizacion: currentState.filtroEstadoCotizacion,
                        );
                  }
                },
              ),
              tittle: 'Filtros Adicionales',
              allowButtons: false,
              showButtoms: false,
            );
          },
          icon: const Icon(Icons.filter_list_outlined, color: ColorSchema.primaryColor),
          label: const Text(
            'Mas filtros',
            style: TextStyle(
              color: ColorSchema.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          style: TextButton.styleFrom(foregroundColor: ColorSchema.primaryColor),
        ),
      ],
    );
  }
}
