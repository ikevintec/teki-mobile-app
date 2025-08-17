import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class SummaryBarSales extends ConsumerStatefulWidget {
  const SummaryBarSales({super.key});

  @override
  ConsumerState<SummaryBarSales> createState() => _SummaryBarSalesState();
}

class _SummaryBarSalesState extends ConsumerState<SummaryBarSales> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final providerTicket = ref.watch(ticketProvider);
    final provider = ref.watch(productSaleProvider);

    return Container(
      padding: const EdgeInsets.only(top: 5, bottom: 15, left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            width: 0.4,
            color: ColorSchema.primaryColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                    Text(
                      "${formatExchange(moneda: provider.currency != null ? (provider.currency!.codigoMoneda ?? 'U') : '')} ${(providerTicket.ticket.totalVenta ?? 0).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (isExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Gravada",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${formatExchange(moneda: provider.currency != null ? (provider.currency!.codigoMoneda ?? 'U') : '')} ${(providerTicket.ticket.totalValorVentaGravada ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (isExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Otros cargos",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${formatExchange(moneda: provider.currency != null ? (provider.currency!.codigoMoneda ?? 'U') : '')} ${(providerTicket.ticket.otrosCargos ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (isExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Otros tributos",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${formatExchange(moneda: provider.currency != null ? (provider.currency!.codigoMoneda ?? 'U') : '')} ${(providerTicket.ticket.otrosTributos ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (isExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "IGV",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${formatExchange(moneda: provider.currency != null ? (provider.currency!.codigoMoneda ?? 'U') : '')} ${(providerTicket.ticket.totalIgv ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if ((providerTicket.ticket.totalValorVentaGratuita ?? 0) > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Gratuita",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${formatExchange(moneda: provider.currency != null ? (provider.currency!.codigoMoneda ?? 'U') : '')} ${(providerTicket.ticket.totalValorVentaGratuita ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: ColorSchema.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
