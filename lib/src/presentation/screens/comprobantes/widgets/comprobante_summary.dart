import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

/// Widget de totales, reutilizado por el flujo de ventas (Ticket) y el de
/// cotizaciones (Quotation) sin mezclar sus repositorios: ambos modelos
/// comparten los mismos nombres de campo de totales, así que solo se lee
/// el que esté presente (ticket ?? quotation) según cuál se haya pasado.
class ComprobanteSummaryWidget extends StatelessWidget {
  final Ticket? ticket;
  final Quotation? quotation;

  const ComprobanteSummaryWidget({super.key, this.ticket, this.quotation});

  double? get totalVenta => ticket?.totalVenta ?? quotation?.totalVenta;
  String? get codigoMoneda => ticket?.codigoMoneda ?? quotation?.codigoMoneda;
  double? get totalValorVentaGravada => ticket?.totalValorVentaGravada ?? quotation?.totalValorVentaGravada;
  double? get totalValorVentaInafecta => ticket?.totalValorVentaInafecta ?? quotation?.totalValorVentaInafecta;
  double? get totalValorVentaExonerada => ticket?.totalValorVentaExonerada ?? quotation?.totalValorVentaExonerada;
  double? get totalValorVentaExportacion => ticket?.totalValorVentaExportacion ?? quotation?.totalValorVentaExportacion;
  double? get totalIsc => ticket?.totalIsc ?? quotation?.totalIsc;
  double? get totalTributosBolsas => ticket?.totalTributosBolsas ?? quotation?.totalTributosBolsas;
  double? get otrosCargos => ticket?.otrosCargos ?? quotation?.otrosCargos;
  double? get totalDescuento => ticket?.totalDescuento ?? quotation?.totalDescuento;
  double? get totalIgv => ticket?.totalIgv ?? quotation?.totalIgv;
  double? get totalValorVentaGratuita => ticket?.totalValorVentaGratuita ?? quotation?.totalValorVentaGratuita;

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
                style: GoogleFonts.roboto(
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
                      text: '${formatExchange(moneda: codigoMoneda ?? "PEN")} ',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorSchema.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                    TextSpan(
                      text: totalVenta?.toStringAsFixed(2) ?? '--',
                      style: GoogleFonts.roboto(
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
            totalValorVentaGravada,
            codigoMoneda,
          ),
          if ((totalValorVentaInafecta ?? 0) > 0)
            _buildSummaryRow('Inafecta', totalValorVentaInafecta, codigoMoneda),
          if ((totalValorVentaExonerada ?? 0) > 0)
            _buildSummaryRow('Exonerada', totalValorVentaExonerada, codigoMoneda),
          if ((totalValorVentaExportacion ?? 0) > 0)
            _buildSummaryRow('Exportación', totalValorVentaExportacion, codigoMoneda),
          if ((totalIsc ?? 0) > 0)
            _buildSummaryRow('ISC', totalIsc, codigoMoneda),
          if ((totalTributosBolsas ?? 0) > 0)
            _buildSummaryRow('ICBPER', totalTributosBolsas, codigoMoneda),
          if ((otrosCargos ?? 0) > 0)
            _buildSummaryRow('Otros Cargos', otrosCargos, codigoMoneda),
          if ((totalDescuento ?? 0) > 0)
            _buildSummaryRow('Descuento', -(totalDescuento ?? 0), codigoMoneda, isDiscount: true),
          if ((totalIgv ?? 0) > 0)
            _buildSummaryRow('IGV', totalIgv, codigoMoneda, isIgv: true),
          if ((totalValorVentaGratuita ?? 0) > 0) ...[
            Divider(color: Colors.grey[300], thickness: 1),
            _buildSummaryRow('Gratuita', totalValorVentaGratuita, codigoMoneda, isGratuita: true),
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
            style: GoogleFonts.roboto(fontSize: 14, fontWeight: fontWeight, color: textColor),
          ),
          Text(
            '${formatExchange(moneda: currency ?? "PEN")} ${(value ?? 0).toStringAsFixed(2)}',
            style: GoogleFonts.roboto(fontSize: 14, fontWeight: fontWeight, color: textColor),
          ),
        ],
      ),
    );
  }
}
