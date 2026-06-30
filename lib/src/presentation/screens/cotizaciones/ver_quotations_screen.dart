import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:teki_app/src/presentation/screens/comprobantes/widgets/calendar_filter.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/list_quotations.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/widgets/quotation_clean_filters_button.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/widgets/quotation_filter_actions.dart';

import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/quotation/quotation_list_provider.dart';

import 'package:teki_app/src/utils/contstants.dart';

class VerQuotationsScreen extends ConsumerStatefulWidget {
  const VerQuotationsScreen({super.key});

  @override
  ConsumerState<VerQuotationsScreen> createState() => _VerQuotationsScreenState();
}

class _VerQuotationsScreenState extends ConsumerState<VerQuotationsScreen> {
  void _reloadWithCurrentDate() {
    final state = ref.read(quotationListProvider);
    final desde = state.filtroDesde;
    final hasta = state.filtroHasta;
    if (desde.isNotEmpty && hasta.isNotEmpty) {
      ref.read(quotationListProvider.notifier).loadFirstPage(desde: desde, hasta: hasta);
    }
  }

  void _handleDateRangeChanged(DateTimeRange range) {
    final provider = ref.read(quotationListProvider.notifier);
    final desde = DateFormat('dd-MM-yyyy H:mm:ss')
        .format(DateTime(range.start.year, range.start.month, range.start.day, 0, 0, 0));
    final hasta = DateFormat('dd-MM-yyyy H:mm:ss')
        .format(DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59));
    provider.loadFirstPage(desde: desde, hasta: hasta);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sesionProvider, (prev, next) {
      if (next.office?.id != prev?.office?.id) _reloadWithCurrentDate();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ver Cotizaciones', style: TextStyle(color: Colors.white)),
        backgroundColor: ColorSchema.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CustomDatePicker(
              onDateSelected: _handleDateRangeChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                QuotationFilterActions(),
                QuotationCleanFiltersButton(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: QuotationListSection(),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
