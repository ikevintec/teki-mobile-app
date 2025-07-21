import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/presentation/screens/viewer/pdf_viewer_screen.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/utils/contstants.dart';

/// Muestra el modal personalizado con los detalles del comprobante
void showTicketDetailsCustomModal(BuildContext context, Ticket ticket) {
  showCustomModal(
    context: context,
    child:_TicketDetailContent(ticket),
    tittle: 'Detalle del Comprobante',
    allowButtons: false,
  );
}

/// Widget con el contenido visual del modal
class _TicketDetailContent extends StatelessWidget {
  final Ticket ticket;

  const _TicketDetailContent(this.ticket);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icono decorativo
        const Icon(Icons.receipt_long,
            color: ColorSchema.primaryColor, size: 40),
        const SizedBox(height: 12),

        // Card de contenido
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Serie - Número",
                  '${ticket.serie ?? '--'} - ${ticket.numero ?? '--'}'),
              _buildDetailRow("Fecha",
                  '${ticket.fechaEmision ?? '--'} ${ticket.horaEmision ?? ''}'),

              const SizedBox(height: 16),
              Divider(color: Colors.grey[400]),
              const SizedBox(height: 8),

              // Datos del cliente
              Text("Cliente:",
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black)),
              const SizedBox(height: 4),
              Text(ticket.denominacionReceptor ?? "Sin nombre",
                  style: GoogleFonts.nunito(fontSize: 14, color: Colors.black)),
              if (ticket.emailReceptor?.isNotEmpty ?? false)
                Text("📧 ${ticket.emailReceptor!}",
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: Colors.grey[700])),
              if (ticket.telefonoReceptor?.isNotEmpty ?? false)
                Text("📞 ${ticket.telefonoReceptor!}",
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: Colors.grey[700])),

              const SizedBox(height: 16),
              Divider(color: Colors.grey[400]),
              const SizedBox(height: 8),

              // Otros datos
              _buildDetailRow(
                "Anulado",
                ticket.anulado == null
                    ? "No especificado"
                    : (ticket.anulado! ? "Sí" : "No"),
              ),
              _buildDetailRow("RUC Emisor", ticket.rucEmisor ?? "--"),

              // Total destacado
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ${ticket.totalVenta?.toStringAsFixed(2) ?? "--"} ${ticket.codigoMoneda ?? ""}',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPdfIconButton(
              icon: Icons.description,
              label: 'Ver PDF',
              onPressed: () {
                Get.to(() => PdfViewerScreen(
                  uuid: ticket.uuid!,
                  fileName: ticket.identificadorDocumento!,
                ));
              },
            ),
            const SizedBox(width: 40),
            _buildPdfIconButton(
              icon: Icons.confirmation_number,
              label: 'Ver Ticket',
              onPressed: () {
                Get.to(() => PdfViewerScreen(
                  uuid: ticket.uuid!,
                  fileName: ticket.identificadorDocumento!,
                  fileSize: 'TICKET',
                ));
              },
            ),
          ],
        )

      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, color: Colors.black)),
          Expanded(
            child: Text(value, style: GoogleFonts.nunito(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

Widget _buildPdfIconButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(icon),
        tooltip: label,
        color: ColorSchema.primaryColor,
        iconSize: 30,
        onPressed: onPressed,
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      )
    ],
  );
}

