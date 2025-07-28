import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/presentation/screens/viewer/pdf_viewer_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class ViewComponentScreen extends StatelessWidget {
  final Ticket ticket;

  const ViewComponentScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Detalle del comprobante",
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Image.asset(
                        'assets/icons/icon_image/whatsap.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: Image.asset(
                        'assets/icons/icon_image/gmail.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Datos del cliente
                          Text(
                            "Comprobante",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 6, // Ajusta según tu diseño
                            children: [
                              _buildDetailRow(
                                "Tipo",
                                formatTipoComprobante(
                                    ticket.tipoComprobante ?? ''),
                              ),
                              _buildDetailRow(
                                "Serie",
                                ticket.serie ?? '--',
                              ),
                              _buildDetailRow(
                                "Número",
                                ticket.numero?.toString() ?? '--',
                              ),
                              _buildDetailRow(
                                "Fecha",
                                ticket.fechaEmision ?? '--',
                              ),
                              _buildDetailRow(
                                "Hora",
                                ticket.horaEmision ?? '--',
                              ),
                              _buildDetailRow(
                                "Tipo Pago",
                                ticket.tipoVenta ?? '--',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Divider(color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          // Datos del cliente
                          Text(
                            "Cliente",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          //Datos del cliente
                          _buildDetailRow(
                            "Nombre",
                            ticket.denominacionReceptor ?? "Sin nombre",
                          ),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 6, // Ajusta según tu diseño
                            children: [
                              _buildDetailRow(
                                "Genero",
                                ticket.cliente?.genero ?? "--",
                              ),
                              _buildDetailRow(
                                "Teléfono",
                                ticket.telefonoReceptor ?? '--',
                              ),
                            ],
                          ),

                          _buildDetailRow(
                            "Email",
                            ticket.emailReceptor?.isNotEmpty == true
                                ? ticket.emailReceptor!
                                : "--",
                          ),
                          _buildDetailRow(
                            "Dirección",
                            ticket.cliente?.direccion ?? "--",
                          ),
                          const SizedBox(height: 18),
                          Divider(color: Colors.grey[300]),
                          // Datos de Emisor
                          Text(
                            "Emisor",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildDetailRow(
                            "Razon social",
                            ticket.razonSocialEmisor ?? "--",
                          ),
                          _buildDetailRow(
                            "RUC Emisor",
                            ticket.rucEmisor ?? "--",
                          ),
                          // Total destacado
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 217, 239, 255),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              '${formatExchange(moneda: ticket.codigoMoneda ?? "PEN")} ${ticket.totalVenta?.toStringAsFixed(2) ?? "--"}',
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        if ((ticket.totalValorVentaGratuita ?? 0) > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gratuita',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                '${formatExchange(moneda: ticket.codigoMoneda ?? "PEN")} ${ticket.totalValorVentaGratuita?.toStringAsFixed(2) ?? "--"}',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildPdfActionButton(
                          icon: Icons.description,
                          label: 'Ver PDF',
                          onPressed: () {
                            Get.to(() => PdfViewerScreen(
                                  uuid: ticket.uuid!,
                                  fileName: ticket.identificadorDocumento!,
                                ));
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildPdfActionButton(
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPdfActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorSchema.primaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    icon: Icon(icon, size: 24),
    label: Text(label),
    onPressed: onPressed,
  );
}
