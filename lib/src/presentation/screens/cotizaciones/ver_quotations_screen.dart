import 'package:teki_app/src/presentation/screens/cotizaciones/quotation_navigation.dart';
import 'package:teki_app/src/presentation/screens/dashboard/navigation/dashboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:teki_app/src/presentation/screens/comprobantes/widgets/calendar_filter.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/list_quotations.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/widgets/quotation_clean_filters_button.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/widgets/quotation_filter_actions.dart';

import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/quotation/quotation_list_provider.dart';

import 'package:teki_app/src/utils/constants.dart';

class VerQuotationsScreen extends ConsumerStatefulWidget {
  const VerQuotationsScreen({super.key});

  @override
  ConsumerState<VerQuotationsScreen> createState() =>
      _VerQuotationsScreenState();
}

class _VerQuotationsScreenState extends ConsumerState<VerQuotationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(sesionProvider.notifier).cargarDistribuidor(),
    );
  }

  void _reloadWithCurrentDate() {
    final state = ref.read(quotationListProvider);
    final desde = state.filtroDesde;
    final hasta = state.filtroHasta;
    if (desde.isNotEmpty && hasta.isNotEmpty) {
      ref
          .read(quotationListProvider.notifier)
          .loadFirstPage(desde: desde, hasta: hasta);
    }
  }

  void _handleDateRangeChanged(DateTimeRange range) {
    final provider = ref.read(quotationListProvider.notifier);
    final desde = DateFormat('dd-MM-yyyy H:mm:ss').format(
      DateTime(range.start.year, range.start.month, range.start.day, 0, 0, 0),
    );
    final hasta = DateFormat('dd-MM-yyyy H:mm:ss').format(
      DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
    provider.loadFirstPage(desde: desde, hasta: hasta);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sesionProvider, (prev, next) {
      if (next.office?.id != prev?.office?.id) _reloadWithCurrentDate();
    });

    return Scaffold(
      floatingActionButton:
          dashboardAllows(ref.watch(sesionProvider), 'VENTAS_CREAR')
          ? FloatingActionButton.extended(
              onPressed: () => openNewQuotation(
                context,
                ref,
                isPedido: ref.read(quotationListProvider).esPedido,
              ),
              icon: const Icon(Icons.add),
              label: Text(
                ref.watch(quotationListProvider).esPedido
                    ? 'Nuevo pedido'
                    : 'Nueva cotización',
              ),
            )
          : null,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          ref.watch(quotationListProvider).esPedido
              ? 'Pedidos'
              : 'Cotizaciones',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorSchema.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if ([
            'preciosComerciales',
            'promociones',
            'reservarStockPedidos',
          ].any((key) => ref.watch(sesionProvider).distribuidor[key] == true))
            Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Cotizaciones')),
                  ButtonSegment(value: true, label: Text('Pedidos')),
                ],
                selected: {ref.watch(quotationListProvider).esPedido},
                onSelectionChanged: (s) => ref
                    .read(quotationListProvider.notifier)
                    .cambiarModoPedido(s.first),
              ),
            ),
          if (ref.watch(quotationListProvider).esPedido &&
              (ref.watch(sesionProvider).hasPermission('PEDIDOS_VER_AJENOS') ||
                  ref.watch(sesionProvider).hasPermission('SUPER_USUARIO')))
            SwitchListTile(
              title: const Text('Ver pedidos de otros vendedores'),
              value: ref.watch(quotationListProvider).todosVendedores,
              onChanged: (value) => ref
                  .read(quotationListProvider.notifier)
                  .cambiarVendedores(value),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CustomDatePicker(onDateSelected: _handleDateRangeChanged),
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
