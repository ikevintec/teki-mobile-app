import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class ComprobanteSummaryWidget extends StatefulWidget {
  final Ticket ticket;

  const ComprobanteSummaryWidget({super.key, required this.ticket});

  @override
  State<ComprobanteSummaryWidget> createState() => _ComprobanteSummaryWidgetState();
}

class _ComprobanteSummaryWidgetState extends State<ComprobanteSummaryWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorSchema.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorSchema.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(isExpanded ? 0 : 12),
                bottomRight: Radius.circular(isExpanded ? 0 : 12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: ColorSchema.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${formatExchange(moneda: widget.ticket.codigoMoneda ?? "PEN")} ${widget.ticket.totalVenta?.toStringAsFixed(2) ?? "--"}',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
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
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Subtotal (Gravada)',
                    widget.ticket.totalValorVentaGravada,
                    widget.ticket.codigoMoneda,
                  ),
                  if ((widget.ticket.totalValorVentaInafecta ?? 0) > 0)
                    _buildSummaryRow(
                      'Inafecta',
                      widget.ticket.totalValorVentaInafecta,
                      widget.ticket.codigoMoneda,
                    ),
                  if ((widget.ticket.totalValorVentaExonerada ?? 0) > 0)
                    _buildSummaryRow(
                      'Exonerada',
                      widget.ticket.totalValorVentaExonerada,
                      widget.ticket.codigoMoneda,
                    ),
                  if ((widget.ticket.totalValorVentaExportacion ?? 0) > 0)
                    _buildSummaryRow(
                      'Exportación',
                      widget.ticket.totalValorVentaExportacion,
                      widget.ticket.codigoMoneda,
                    ),
                  if ((widget.ticket.totalIsc ?? 0) > 0)
                    _buildSummaryRow(
                      'ISC',
                      widget.ticket.totalIsc,
                      widget.ticket.codigoMoneda,
                    ),
                  if ((widget.ticket.totalTributosBolsas ?? 0) > 0)
                    _buildSummaryRow(
                      'ICBPER',
                      widget.ticket.totalTributosBolsas,
                      widget.ticket.codigoMoneda,
                    ),
                  if ((widget.ticket.otrosCargos ?? 0) > 0)
                    _buildSummaryRow(
                      'Otros Cargos',
                      widget.ticket.otrosCargos,
                      widget.ticket.codigoMoneda,
                    ),
                  if ((widget.ticket.totalDescuento ?? 0) > 0)
                    _buildSummaryRow(
                      'Descuento',
                      -(widget.ticket.totalDescuento ?? 0),
                      widget.ticket.codigoMoneda,
                      isDiscount: true,
                    ),
                  if ((widget.ticket.totalIgv ?? 0) > 0)
                    _buildSummaryRow(
                      'IGV',
                      widget.ticket.totalIgv,
                      widget.ticket.codigoMoneda,
                      isIgv: true,
                    ),
                  if ((widget.ticket.totalValorVentaGratuita ?? 0) > 0) ...
                  [
                    Divider(color: Colors.grey[300], thickness: 1),
                    _buildSummaryRow(
                      'Gratuita',
                      widget.ticket.totalValorVentaGratuita,
                      widget.ticket.codigoMoneda,
                      isGratuita: true,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double? value,
    String? currency, {
    bool isIgv = false,
    bool isDiscount = false,
    bool isGratuita = false,
  }) {
    Color textColor = Colors.grey[700]!;
    FontWeight fontWeight = FontWeight.normal;
    
    if (isIgv) {
      textColor = Colors.orange[700]!;
      fontWeight = FontWeight.w600;
    } else if (isDiscount) {
      textColor = Colors.red[600]!;
      fontWeight = FontWeight.w600;
    } else if (isGratuita) {
      textColor = Colors.green[600]!;
      fontWeight = FontWeight.w600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
          Text(
            '${formatExchange(moneda: currency ?? "PEN")} ${(value ?? 0).toStringAsFixed(2)}',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
