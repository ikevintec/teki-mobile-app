import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class SummaryBarSales extends ConsumerStatefulWidget {
  final bool showOnlyTotal;
  final bool isProcessingTotal;
  final bool showIndicatorKeyboard;
  final bool showMontoPagado;
  final bool showCambio;
  final double montoPagado;
  final double cambio;

  const SummaryBarSales({
    super.key,
    this.showOnlyTotal = false,
    this.isProcessingTotal = false,
    this.showIndicatorKeyboard = false,
    this.showMontoPagado = false,
    this.showCambio = false,
    this.montoPagado = 0,
    this.cambio = 0,
  });

  @override
  ConsumerState<SummaryBarSales> createState() => _SummaryBarSalesState();
}

class _SummaryBarSalesState extends ConsumerState<SummaryBarSales>
    with WidgetsBindingObserver {
  bool isExpanded = false;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final visible = bottomInset > 0;
    if (visible != _isKeyboardVisible) {
      setState(() => _isKeyboardVisible = visible);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerTicket = ref.watch(ticketProvider);
    final provider = ref.watch(productSaleProvider);

    return widget.showIndicatorKeyboard && _isKeyboardVisible ? Center(child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: const Icon(Icons.keyboard_arrow_down_outlined, size: 20, color: ColorSchema.primaryColor),
      ),
    )) : Container(
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
                if (widget.showMontoPagado)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Pagado",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                      Text(
                        "${formatExchange(moneda: provider.currency != null ? (provider.currency!.codigoMoneda ?? 'U') : '')} ${widget.montoPagado.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                if (widget.showCambio && widget.cambio > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Cambio",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                      ),
                      Text(
                        "${formatExchange(moneda: provider.currency != null ? (provider.currency!.codigoMoneda ?? 'U') : '')} ${widget.cambio.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                if (!widget.showOnlyTotal && isExpanded)
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
                if (!widget.showOnlyTotal && isExpanded)
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
                if (!widget.showOnlyTotal && isExpanded)
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
                if (!widget.showOnlyTotal && isExpanded)
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
                if (!widget.showOnlyTotal && (providerTicket.ticket.totalValorVentaGratuita ?? 0) > 0)
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
          if (!widget.showOnlyTotal)
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
