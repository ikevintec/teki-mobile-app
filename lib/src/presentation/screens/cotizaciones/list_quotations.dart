import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/view_quotation_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/quotation/quotation_list_provider.dart';
import 'package:teki_app/src/shared/widgets/dismissible_action_widget.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

class QuotationListSection extends ConsumerStatefulWidget {
  const QuotationListSection({super.key});

  @override
  ConsumerState<QuotationListSection> createState() =>
      _QuotationListSectionState();
}

class _QuotationListSectionState extends ConsumerState<QuotationListSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final state = ref.read(quotationListProvider);

      final reachedEnd =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300;

      if (reachedEnd && state.hasMore && !state.isLoading) {
        ref.read(quotationListProvider.notifier).fetchMoreQuotations();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmAnular(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Anular cotización'),
        content: const Text(
          '¿Estás seguro de que deseas anular esta cotización?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(quotationListProvider.notifier)
                  .deleteQuotation(id);
              if (success) {
                successNotification('Cotización anulada correctamente');
              }
            },
            child: const Text('Anular', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'CONCRETADA':
        return Colors.green;
      case 'ANULADA':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _onRefresh() async {
    final state = ref.read(quotationListProvider);
    await ref
        .read(quotationListProvider.notifier)
        .loadFirstPage(
          desde: state.filtroDesde,
          hasta: state.filtroHasta,
          serie: state.filtroSerie,
          numero: state.filtroNumero,
          estadoCotizacion: state.filtroEstadoCotizacion,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(quotationListProvider);
    final quotations = provider.quotations;
    final hasMore = provider.hasMore;
    final isLoading = provider.isLoading;

    final isInitialLoad = isLoading && quotations.isEmpty;

    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quotations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: Text("No hay cotizaciones por mostrar.")),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: quotations.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == quotations.length && hasMore) {
            final state = ref.read(quotationListProvider);
            if (!state.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(quotationListProvider.notifier).fetchMoreQuotations();
              });
            }

            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final quotation = quotations[index];
          final isAnulada = quotation.estadoCotizacion == 'ANULADA';
          final isConcretada = quotation.estadoCotizacion == 'CONCRETADA';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DismissibleActionWidget(
              actions: (isAnulada || isConcretada)
                  ? []
                  : [
                      DismissibleActionData(
                        type: DismissibleActionType.edit,
                        label: 'Editar',
                        icon: Icons.edit,
                        backgroundColor: Colors.orange.shade600,
                        onTap: () {
                          Get.to(
                            () => ProductsSaleScreen(quotationId: quotation.id),
                          );
                        },
                      ),
                      DismissibleActionData(
                        type: DismissibleActionType.anular,
                        label: 'Anular',
                        icon: Icons.cancel_outlined,
                        backgroundColor: Colors.red.shade600,
                        onTap: () => _confirmAnular(quotation.id ?? -1),
                      ),
                      DismissibleActionData(
                        type: DismissibleActionType.generarVenta,
                        label: 'Generar venta',
                        icon: Icons.point_of_sale,
                        backgroundColor: Colors.green.shade600,
                        onTap: () {
                          Get.to(
                            () => ProductsSaleScreen(
                              quotationIdForSale: quotation.id,
                            ),
                          );
                        },
                      ),
                    ],
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: ListTile(
                      leading: const Icon(
                        Icons.request_quote_outlined,
                        size: 35,
                        color: ColorSchema.primaryColor,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cotización',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${quotation.serie ?? '--'} - ${quotation.numero ?? '--'}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Fecha de emisión: ${quotation.fechaEmision ?? "--"}',
                            style: GoogleFonts.roboto(fontSize: 11),
                          ),
                          Text(
                            quotation.denominacionReceptor ?? '--',
                            style: GoogleFonts.roboto(fontSize: 11),
                          ),
                          Text(
                            quotation.estadoCotizacion ?? '--',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: _estadoColor(quotation.estadoCotizacion),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${formatExchange(moneda: quotation.codigoMoneda ?? "PEN")}${quotation.totalVenta?.toStringAsFixed(2) ?? "--"}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: ColorSchema.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            quotation.tipoVenta == 'CONTADO'
                                ? 'Al contado'
                                : 'Al crédito',
                            style: GoogleFonts.roboto(fontSize: 11),
                          ),
                        ],
                      ),
                      onTap: () {
                        Get.to(
                          () => ViewQuotationScreen(id: quotation.id ?? -1),
                        );
                      },
                    ),
                  ),
                  Divider(color: Colors.grey[300]!, height: 0.2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
