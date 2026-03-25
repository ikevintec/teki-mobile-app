import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class ComprobanteSummaryWidget extends StatelessWidget {
  final Ticket ticket;

  const ComprobanteSummaryWidget({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorSchema.primaryColor.withValues(alpha: 0.7),
                  letterSpacing: 1.1,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${formatExchange(moneda: ticket.codigoMoneda ?? "PEN")} ',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorSchema.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                    TextSpan(
                      text: ticket.totalVenta?.toStringAsFixed(2) ?? '--',
                      style: GoogleFonts.nunito(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: ColorSchema.primaryColor.withValues(alpha: 0.3), thickness: 1),
          _buildSummaryRow(
            'Subtotal (Gravada)',
            ticket.totalValorVentaGravada,
            ticket.codigoMoneda,
          ),
          if ((ticket.totalValorVentaInafecta ?? 0) > 0)
            _buildSummaryRow('Inafecta', ticket.totalValorVentaInafecta, ticket.codigoMoneda),
          if ((ticket.totalValorVentaExonerada ?? 0) > 0)
            _buildSummaryRow('Exonerada', ticket.totalValorVentaExonerada, ticket.codigoMoneda),
          if ((ticket.totalValorVentaExportacion ?? 0) > 0)
            _buildSummaryRow('Exportación', ticket.totalValorVentaExportacion, ticket.codigoMoneda),
          if ((ticket.totalIsc ?? 0) > 0)
            _buildSummaryRow('ISC', ticket.totalIsc, ticket.codigoMoneda),
          if ((ticket.totalTributosBolsas ?? 0) > 0)
            _buildSummaryRow('ICBPER', ticket.totalTributosBolsas, ticket.codigoMoneda),
          if ((ticket.otrosCargos ?? 0) > 0)
            _buildSummaryRow('Otros Cargos', ticket.otrosCargos, ticket.codigoMoneda),
          if ((ticket.totalDescuento ?? 0) > 0)
            _buildSummaryRow('Descuento', -(ticket.totalDescuento ?? 0), ticket.codigoMoneda, isDiscount: true),
          if ((ticket.totalIgv ?? 0) > 0)
            _buildSummaryRow('IGV', ticket.totalIgv, ticket.codigoMoneda, isIgv: true),
          if ((ticket.totalValorVentaGratuita ?? 0) > 0) ...[
            Divider(color: Colors.grey[300], thickness: 1),
            _buildSummaryRow('Gratuita', ticket.totalValorVentaGratuita, ticket.codigoMoneda, isGratuita: true),
          ],
          const SizedBox(height: 4),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: fontWeight, color: textColor),
          ),
          Text(
            '${formatExchange(moneda: currency ?? "PEN")} ${(value ?? 0).toStringAsFixed(2)}',
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: fontWeight, color: textColor),
          ),
        ],
      ),
    );
  }
}
