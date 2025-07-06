import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
                      ),
                    ),
                    Text(
                      "${formatExchange(moneda: provider.currency!.codigoMoneda!)} ${(providerTicket.ticket.totalVenta ?? 0).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
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
                        "${formatExchange(moneda: provider.currency!.codigoMoneda!)} ${(providerTicket.ticket.totalValorVentaGravada ?? 0).toStringAsFixed(2)}",
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
                        "${formatExchange(moneda: provider.currency!.codigoMoneda!)} ${(providerTicket.ticket.otrosCargos ?? 0).toStringAsFixed(2)}",
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
                        "${formatExchange(moneda: provider.currency!.codigoMoneda!)} ${(providerTicket.ticket.otrosTributos ?? 0).toStringAsFixed(2)}",
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
                        "${formatExchange(moneda: provider.currency!.codigoMoneda!)} ${(providerTicket.ticket.totalIgv ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 12,
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
