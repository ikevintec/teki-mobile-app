import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/comprobante_summary.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/form_send_whatsapp.dart';
import 'package:teki_app/src/utils/whatsapp_helper.dart';
import 'package:teki_app/src/presentation/screens/viewer/pdf_viewer_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/presentation/widgets/dropdown_action_button/dropdown_action_button.dart';
import 'package:teki_app/src/presentation/widgets/celebration/success_celebration_overlay.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/presentation/widgets/split_action_button/split_action_button.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewComponentScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  final int? id;
  final bool fromSale;

  const ViewComponentScreen({super.key, required this.ticket, this.id, this.fromSale = false});

  @override
  ConsumerState<ViewComponentScreen> createState() => _ViewComponentScreenState();
}

class _ViewComponentScreenState extends ConsumerState<ViewComponentScreen> {
  @override
  void initState() {
    super.initState();

    if (widget.id != null && widget.id! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(comprobanteProvider.notifier).fetchComprobanteById(widget.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(comprobanteProvider);
    final ticketToShow = _getTicketToDisplay(provider, widget.ticket, widget.id);

    if (widget.id != null && provider.isLoading) {
      return const ScreenLoader(message: 'Cargando Comprobante...');
    }

    if (widget.id != null && !provider.isLoading && (provider.ticket.id ?? 0) <= 0) {
      return _buildErrorScreen("Comprobante no encontrado.", widget.fromSale);
    }

    return Stack(
      children: [
        // ── Scaffold principal ──────────────────────────────────────
        Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: CustomAppBar(
              navigateName: "Detalle",
              navigateRoute: widget.fromSale ? AppRoutes.dashboard : null,
            ),
          ),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Header ───────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Column(
                            children: [
                              Text(
                                '${formatTipoComprobanteTitulo(ticketToShow.tipoComprobante ?? '')} electrónica',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: ColorSchema.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ticketToShow.serie} - ${ticketToShow.numero}',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[700],
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if ((ticketToShow.denominacionReceptor ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  ticketToShow.denominacionReceptor!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _buildSunatBadge(ticketToShow.estadoSunat),
                              ),
                            ],
                          ),
                        ),
                        // ── Acciones ─────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 20),
                          child: Row(
                            children: [
                              Expanded(child: _buildSendDropdown(
                                ticketToShow,
                                context,
                                ref.watch(sesionProvider).company?.nombreComercial ?? 'Empresa',
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _PrintButton(ticket: ticketToShow)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 20),
                          child: _buildDocsDropdown(ticketToShow, context, ref.watch(sesionProvider).config?.tipoImpresion ?? 'A4'),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 20),
                          child: _DownloadButton(ticket: ticketToShow),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 24),
                          child: _buildVerComprobantesButton(context, widget.fromSale),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildComprobanteSummary(ticketToShow),
                ),
              ],
            ),
          ),
        ),                     // Scaffold
        SuccessCelebrationOverlay(show: widget.fromSale),
      ],
    );
  }
}


Ticket _getTicketToDisplay(ComprobanteState provider, Ticket defaultTicket, int? id) {
  if (id != null && (provider.ticket.id ?? 0) > 0) {
    return provider.ticket;
  }
  return defaultTicket;
}

// Helper method to build error screen
Widget _buildErrorScreen(String message, bool fromSale) {
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: CustomAppBar(
        navigateName: "Detalle",
        navigateRoute: fromSale ? AppRoutes.dashboard : null,
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.roboto(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (fromSale) {
                Get.offAllNamed(AppRoutes.dashboard);
              } else {
                Get.back();
              }
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    ),
  );
}

  // Widget methods for better organization
  Widget _buildComprobanteSummary(Ticket ticket) {
    return ComprobanteSummaryWidget(ticket: ticket);
  }



  Widget _buildSunatBadge(String? estado) {
    Color color;
    IconData icon;
    String label;
    switch (estado) {
      case 'ACEPT':
        color = Colors.green.shade600; icon = Icons.verified; label = 'Aceptado'; break;
      case 'RECHA':
        color = Colors.red.shade600; icon = Icons.gpp_bad; label = 'Rechazado'; break;
      case 'ANULA':
        color = Colors.orange.shade700; icon = Icons.block; label = 'Anulado'; break;
      case 'N_ENV':
        color = Colors.grey.shade500; icon = Icons.cloud_off; label = 'No enviado'; break;
      default:
        color = Colors.grey.shade500; icon = Icons.hourglass_empty; label = 'Pendiente'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'SUNAT · $label',
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerComprobantesButton(BuildContext context, bool fromSale) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          if (fromSale) {
            Get.offAllNamed(AppRoutes.dashboard);
            Get.toNamed(AppRoutes.comprobantesVer);
          } else {
            Get.back();
          }
        },
        icon: const Icon(Icons.receipt_long, size: 18),
        label: const Text('Ver Comprobantes'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorSchema.primaryColor,
          side: BorderSide(color: ColorSchema.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSplitButton({
    required BuildContext context,
    required IconData directIcon,
    Widget? directIconWidget,
    required String directLabel,
    required VoidCallback onDirectAction,
    required List<DropdownActionOption> dropdownOptions,
    Color? color,
  }) {
    return SplitActionButton(
      directIcon: directIcon,
      directIconWidget: directIconWidget,
      directLabel: directLabel,
      onDirectAction: onDirectAction,
      dropdownOptions: dropdownOptions,
      color: color ?? ColorSchema.primaryColor,
    );
  }

  Widget _buildSendDropdown(Ticket ticket, BuildContext context, String nombreComercial) {
    return _buildSplitButton(
      context: context,
      directIcon: Icons.chat_rounded,
      directIconWidget: Image.asset(
        'assets/icons/icon_image/whatsapp.png',
        width: 18,
        height: 18,
        color: Colors.white,
      ),
      directLabel: 'Enviar',
      color: const Color(0xFF25D366),
      onDirectAction: () {
        final dataSend = WhatsappHelper.getDataSend(ticket, nombreComercial);
        showCustomModal(
          context: context,
          child: FormSendWhatsapp(
            data: WhatsappSendData(
              initialPhone: ticket.telefonoReceptor,
              message: dataSend.textMessage,
              filename: dataSend.nameMessage,
              documentUrl: dataSend.url,
            ),
          ),
          tittle: 'Enviar por Whatsapp',
          allowButtons: false,
          showButtoms: false,
        );
      },
      dropdownOptions: [],
    );
  }

  Widget _buildDocsDropdown(Ticket ticket, BuildContext context, String tipoImpresion) {
    final isTicket = tipoImpresion == 'TICKET' || tipoImpresion == 'ESCPOS';
    final directLabel = 'Ver PDF';
    final directIcon = isTicket ? Icons.confirmation_number : Icons.description;

    return _buildSplitButton(
      context: context,
      directIcon: directIcon,
      directLabel: directLabel,
      color: ColorSchema.primaryColor,
      onDirectAction: () {
        Get.to(() => PdfViewerScreen(
              uuid: ticket.uuid!,
              fileName: ticket.identificadorDocumento!,
              fileSize: isTicket ? 'TICKET' : null,
              ticketId: ticket.id,
            ));
      },
      dropdownOptions: [
        DropdownActionOption(
          label: 'Formato A4',
          icon: Icons.description,
          iconColor: Colors.blue[600],
          onPressed: () {
            Get.to(() => PdfViewerScreen(
                  uuid: ticket.uuid!,
                  fileName: ticket.identificadorDocumento!,
                  ticketId: ticket.id,
                ));
          },
        ),
        DropdownActionOption(
          label: 'Formato Ticket',
          icon: Icons.confirmation_number,
          iconColor: Colors.blue[600],
          onPressed: () {
            Get.to(() => PdfViewerScreen(
                  uuid: ticket.uuid!,
                  fileName: ticket.identificadorDocumento!,
                  fileSize: 'TICKET',
                  ticketId: ticket.id,
                ));
          },
        ),
      ],
    );
  }

// ── Print Button ──────────────────────────────────────────────────────────────

class _PrintButton extends ConsumerStatefulWidget {
  final Ticket ticket;

  const _PrintButton({required this.ticket});

  @override
  ConsumerState<_PrintButton> createState() => _PrintButtonState();
}

class _PrintButtonState extends ConsumerState<_PrintButton> {
  final ComprobantePrintService _printService = ComprobantePrintService();
  bool _isPrinting = false;

  String _buildPdfUrl(String tipoImpresion) {
    final domain = Environment.apiUrl;
    return '$domain/public/pdf/tickets/${widget.ticket.uuid!}/${widget.ticket.identificadorDocumento!}?tipo=$tipoImpresion';
  }

  Future<void> _handlePrint() async {
    final session = ref.read(sesionProvider);
    final printer = session.saleStation?.impresoraComprobante;
    final escPos = session.config?.imprimeTicketsEscPos ?? false;
    final officeCode = session.office?.codigo ?? '';
    final idCompany = session.companySelected?.id;
    final tipoImpresion = session.config?.tipoImpresion ?? 'A4';

    if (printer == null) return;
    if (widget.ticket.id == null && escPos) return;

    setState(() => _isPrinting = true);
    try {
      await _printService.printComprobante(
        ticketId: widget.ticket.id ?? 0,
        pdfUrl: _buildPdfUrl(tipoImpresion),
        printer: printer,
        escPos: escPos,
        officeCode: officeCode,
        idCompany: idCompany,
      );
    } on PrintCoffeException catch (e) {
      errorNotification(e.message);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sesionProvider);
    final clienteImpresion = session.config?.clienteImpresion;
    final printer = session.saleStation?.impresoraComprobante;
    final canPrint = clienteImpresion == 'COFFE' && printer != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
      onPressed: (canPrint && !_isPrinting) ? _handlePrint : null,
      icon: _isPrinting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.print, size: 18),
      label: Text(
        canPrint ? 'Imprimir en ${printer.nombre}' : 'Sin impresora',
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: canPrint ? ColorSchema.primaryColor : Colors.grey.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    );
  }
}

// ── Download Button ───────────────────────────────────────────────────────────

class _DownloadButton extends ConsumerStatefulWidget {
  final Ticket ticket;

  const _DownloadButton({required this.ticket});

  @override
  ConsumerState<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<_DownloadButton> {
  bool _isDownloading = false;

  String _buildPdfUrl(String tipoImpresion) {
    final domain = Environment.apiUrl;
    return '$domain/public/pdf/tickets/${widget.ticket.uuid!}/${widget.ticket.identificadorDocumento!}?tipo=$tipoImpresion';
  }

  Future<void> _handleDownload(String tipoImpresion) async {
    setState(() => _isDownloading = true);
    try {
      final uri = Uri.parse(_buildPdfUrl(tipoImpresion));
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        errorNotification('No se pudo abrir el comprobante para descarga.');
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoImpresion = ref.watch(sesionProvider).config?.tipoImpresion ?? 'A4';

    return SplitActionButton(
      directIcon: Icons.download,
      directLabel: 'Descargar',
      onDirectAction: _isDownloading ? () {} : () => _handleDownload(tipoImpresion),
      color: Colors.grey.shade800,
      dropdownOptions: [
        DropdownActionOption(
          label: 'Descargar PDF',
          icon: Icons.description,
          iconColor: Colors.blue[600],
          onPressed: () => _handleDownload('A4'),
        ),
        DropdownActionOption(
          label: 'Descargar Ticket',
          icon: Icons.confirmation_number,
          iconColor: Colors.blue[600],
          onPressed: () => _handleDownload('TICKET'),
        ),
      ],
    );
  }
}

