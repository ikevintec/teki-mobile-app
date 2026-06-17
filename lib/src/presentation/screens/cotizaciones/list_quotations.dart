import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/view_quotation_screen.dart';
import 'package:teki_app/src/providers/quotation/quotation_list_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class QuotationListSection extends ConsumerStatefulWidget {
  const QuotationListSection({super.key});

  @override
  ConsumerState<QuotationListSection> createState() => _QuotationListSectionState();
}

class _QuotationListSectionState extends ConsumerState<QuotationListSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final state = ref.read(quotationListProvider);

      final reachedEnd = _scrollController.position.pixels >=
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
      return const Center(child: Text("No hay cotizaciones por mostrar."));
    }

    return ListView.builder(
      controller: _scrollController,
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        quotation.tipoVenta == 'CONTADO' ? 'Al contado' : 'Al crédito',
                        style: GoogleFonts.roboto(fontSize: 11),
                      ),
                    ],
                  ),
                  onTap: () {
                    Get.to(() => ViewQuotationScreen(id: quotation.id ?? -1));
                  },
                ),
              ),
              Divider(color: Colors.grey[300]!, height: 0.2),
            ],
          ),
        );
      },
    );
  }
}
