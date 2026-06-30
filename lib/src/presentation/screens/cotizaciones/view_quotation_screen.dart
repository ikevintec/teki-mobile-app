import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/comprobante_summary.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/form_send_whatsapp.dart';
import 'package:teki_app/src/presentation/screens/viewer/pdf_viewer_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/celebration/success_celebration_overlay.dart';
import 'package:teki_app/src/presentation/widgets/dropdown_action_button/dropdown_action_button.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/presentation/widgets/split_action_button/split_action_button.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/quotation/quotation_view_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/quotation_whatsapp_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de detalle de cotización, separada de ViewComponentScreen
/// (tickets) porque la cotización no tiene estado SUNAT ni tipo de
/// comprobante, y su PDF/impresión funcionan distinto (un solo formato,
/// sin impresora física).
class ViewQuotationScreen extends ConsumerStatefulWidget {
  final int id;
  final bool fromSale;

  const ViewQuotationScreen({super.key, required this.id, this.fromSale = false});

  @override
  ConsumerState<ViewQuotationScreen> createState() => _ViewQuotationScreenState();
}

class _ViewQuotationScreenState extends ConsumerState<ViewQuotationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(quotationViewProvider.notifier).fetchQuotationById(widget.id);
      } catch (_) {
        // El error ya fue notificado dentro del provider.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quotationViewProvider);
    final quotation = state.quotation;

    if (state.isLoading) {
      return const ScreenLoader(message: 'Cargando cotización...');
    }

    if (!state.isLoading && (quotation.id ?? 0) <= 0) {
      return _buildErrorScreen("Cotización no encontrada.", widget.fromSale);
    }

    return Stack(
      children: [
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
                        _buildHeader(quotation),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 20),
                          child: _buildSendButton(
                            quotation,
                            context,
                            ref.watch(sesionProvider).company?.nombreComercial ?? 'Empresa',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 20),
                          child: _buildVerPdfButton(quotation, context),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 20),
                          child: _buildDescargarButton(quotation),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 24),
                          child: _buildVerComprobantesButton(widget.fromSale),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ComprobanteSummaryWidget(quotation: quotation),
                ),
              ],
            ),
          ),
        ),
        SuccessCelebrationOverlay(
          show: widget.fromSale,
          title: '¡Cotización realizada!',
          subtitle: 'La cotización fue registrada con éxito',
        ),
      ],
    );
  }

  Widget _buildHeader(Quotation quotation) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        children: [
          Text(
            'Cotización',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: ColorSchema.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${quotation.serie} - ${quotation.numero}',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
              letterSpacing: 1.2,
            ),
          ),
          if ((quotation.denominacionReceptor ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              quotation.denominacionReceptor!,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSendButton(Quotation quotation, BuildContext context, String nombreComercial) {
    return SplitActionButton(
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
        final url = QuotationWhatsappHelper.getUrlPdf(quotation);
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        showCustomModal(
          context: context,
          child: FormSendWhatsapp(
            data: WhatsappSendData(
              initialPhone: quotation.telefonoReceptor,
              message: QuotationWhatsappHelper.getMessage(quotation, nombreComercial),
              filename: QuotationWhatsappHelper.getFilename(quotation),
              documentUrl: '$url?time=$currentTime',
            ),
          ),
          tittle: 'Enviar por Whatsapp',
          allowButtons: false,
          showButtoms: false,
        );
      },
      dropdownOptions: const <DropdownActionOption>[],
    );
  }

  Widget _buildVerPdfButton(Quotation quotation, BuildContext context) {
    return SplitActionButton(
      directIcon: Icons.description,
      directLabel: 'Ver PDF',
      color: ColorSchema.primaryColor,
      onDirectAction: () {
        Get.to(() => PdfViewerScreen(
              customPdfUrl: QuotationWhatsappHelper.getUrlPdf(quotation),
              fileName: '${quotation.serie}-${quotation.numero}',
              allowPrint: false,
            ));
      },
      dropdownOptions: const <DropdownActionOption>[],
    );
  }

  Widget _buildDescargarButton(Quotation quotation) {
    return SplitActionButton(
      directIcon: Icons.download,
      directLabel: 'Descargar',
      color: Colors.grey.shade800,
      onDirectAction: () async {
        final uri = Uri.parse(QuotationWhatsappHelper.getUrlPdf(quotation));
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          errorNotification('No se pudo abrir la cotización para descarga.');
        }
      },
      dropdownOptions: const <DropdownActionOption>[],
    );
  }

  Widget _buildVerComprobantesButton(bool fromSale) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          if (fromSale) {
            Get.offAllNamed(AppRoutes.dashboard);
            Get.toNamed(AppRoutes.quotationsVer);
          } else {
            Get.back();
          }
        },
        icon: const Icon(Icons.receipt_long, size: 18),
        label: const Text('Ver Cotizaciones'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorSchema.primaryColor,
          side: BorderSide(color: ColorSchema.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

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
