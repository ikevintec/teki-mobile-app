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
import 'package:teki_app/src/presentation/widgets/celebration/success_celebration_overlay.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
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
  // Ancla desde donde revienta el confeti al venir de una venta.
  final GlobalKey _celebrationCheckKey = GlobalKey();

  void _enviarWhatsapp(Ticket ticket) {
    final nombreComercial = ref.read(sesionProvider).company?.nombreComercial ?? 'Empresa';
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
  }

  void _showPdfOptions(Ticket ticket) {
    final tipoImpresion = ref.read(sesionProvider).config?.tipoImpresion ?? 'A4';
    final isTicketDefault = tipoImpresion == 'TICKET' || tipoImpresion == 'ESCPOS';

    void verPdf(String tipo) {
      Navigator.of(context).pop();
      Get.to(() => PdfViewerScreen(
            uuid: ticket.uuid!,
            fileName: ticket.identificadorDocumento!,
            fileSize: tipo,
            ticketId: ticket.id,
          ));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _PdfOptionTile(
              icon: Icons.description_outlined,
              label: 'Ver formato A4',
              isDefault: !isTicketDefault,
              onTap: () => verPdf('A4'),
            ),
            _PdfOptionTile(
              icon: Icons.confirmation_number_outlined,
              label: 'Ver formato Ticket',
              isDefault: isTicketDefault,
              onTap: () => verPdf('TICKET'),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            _PdfOptionTile(
              icon: Icons.download_rounded,
              label: 'Descargar A4',
              onTap: () {
                Navigator.of(context).pop();
                _downloadPdf(ticket, 'A4');
              },
            ),
            _PdfOptionTile(
              icon: Icons.download_rounded,
              label: 'Descargar Ticket',
              onTap: () {
                Navigator.of(context).pop();
                _downloadPdf(ticket, 'TICKET');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(Ticket ticket, String tipo) async {
    final uri = Uri.parse(
      '${Environment.apiUrl}/public/pdf/tickets/${ticket.uuid!}/${ticket.identificadorDocumento!}?tipo=$tipo',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      errorNotification('No se pudo abrir el comprobante para descarga.');
    }
  }

  /// Un solo tap para atender al siguiente cliente. El flujo de venta ya
  /// invalidó los providers al completar, pero se reinvalidan por si el
  /// usuario dejó algo a medias antes de llegar aquí.
  void _nuevaVenta() {
    if (!ref.read(sesionProvider).hasPermission('VENTAS_CREAR')) {
      warningNotification('No tienes permiso para crear ventas');
      return;
    }
    ref.invalidate(ticketProvider);
    ref.invalidate(productSaleProvider);
    ref.invalidate(customerSaleProvider);
    Get.offAllNamed(AppRoutes.dashboard);
    Get.toNamed(AppRoutes.productsSales);
  }

  Widget _buildBottomSaleBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nuevaVenta,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Nueva venta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
                  icon: const Icon(Icons.home_outlined, size: 17),
                  label: const Text('Inicio', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.offAllNamed(AppRoutes.dashboard);
                    Get.toNamed(AppRoutes.comprobantesVer);
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 17),
                  label: const Text('Comprobantes', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                              if (widget.fromSale) ...[
                                AnimatedSuccessCheck(key: _celebrationCheckKey),
                                const SizedBox(height: 16),
                              ],
                              Text(
                                '${formatTipoComprobanteTitulo(ticketToShow.tipoComprobante ?? '')} electrónica',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  fontSize: 30,
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
                              Center(
                                child: _buildSunatBadge(ticketToShow.estadoSunat),
                              ),
                            ],
                          ),
                        ),
                        // ── Total cobrado, junto al check de éxito ───────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: _buildComprobanteSummary(ticketToShow),
                          ),
                        ),
                        // ── Acciones rápidas del documento ───────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: _QuickActionTile(
                                  iconWidget: Image.asset(
                                    'assets/icons/icon_image/whatsapp.png',
                                    width: 20,
                                    height: 20,
                                    color: const Color(0xFF25D366),
                                  ),
                                  label: 'Enviar',
                                  onTap: () => _enviarWhatsapp(ticketToShow),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _PrintButton(ticket: ticketToShow)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _QuickActionTile(
                                  icon: Icons.description_outlined,
                                  label: 'PDF',
                                  onTap: () => _showPdfOptions(ticketToShow),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Siguiente acción del cajero (solo al terminar venta) ─
                if (widget.fromSale) _buildBottomSaleBar(),
              ],
            ),
          ),
        ),                     // Scaffold
        SuccessCelebrationOverlay(
          show: widget.fromSale,
          anchorKey: _celebrationCheckKey,
        ),
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

// ── Quick action tile ─────────────────────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _QuickActionTile({
    this.icon,
    this.iconWidget,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorSchema.primaryColor,
                  ),
                )
              else if (iconWidget != null)
                iconWidget!
              else
                Icon(
                  icon,
                  size: 20,
                  color: enabled ? ColorSchema.primaryColor : Colors.grey.shade400,
                ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.grey.shade800 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PDF option tile (bottom sheet) ────────────────────────────────────────────

class _PdfOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDefault;
  final VoidCallback onTap;

  const _PdfOptionTile({
    required this.icon,
    required this.label,
    this.isDefault = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ColorSchema.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: ColorSchema.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Por defecto',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
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

    return _QuickActionTile(
      icon: Icons.print_rounded,
      label: canPrint ? 'Imprimir' : 'Sin impresora',
      loading: _isPrinting,
      onTap: (canPrint && !_isPrinting) ? _handlePrint : null,
    );
  }
}

