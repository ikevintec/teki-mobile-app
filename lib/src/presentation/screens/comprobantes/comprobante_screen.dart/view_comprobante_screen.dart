import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/comprobante_summary.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/form_send_whatsapp.dart';
import 'package:teki_app/src/presentation/screens/viewer/pdf_viewer_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/presentation/widgets/dropdown_action_button/dropdown_action_button.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/contstants.dart';
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

class _ViewComponentScreenState extends ConsumerState<ViewComponentScreen>
    with TickerProviderStateMixin {
  // Overlay / checkmark
  late final AnimationController _overlayController;
  late final AnimationController _checkController;
  late final Animation<double> _overlayOpacity;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkProgress;
  bool _showOverlay = false;

  // Confetti propio
  late final AnimationController _confettiTickController;
  final List<_ConfettiParticle> _confettiParticles = [];
  final Random _confettiRand = Random();
  bool _confettiEmitting = false;
  double _emitAccumulator = 0;
  Duration? _prevElapsed;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _overlayOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 63),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_overlayController);
    _circleScale = CurvedAnimation(
      parent: _checkController,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _checkProgress = CurvedAnimation(
      parent: _checkController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    // Ticker para física de confetti
    _confettiTickController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tickConfetti);

    if (widget.fromSale) {
      _showOverlay = true;
      _confettiEmitting = true;
      _checkController.forward();
      _overlayController.forward().then((_) {
        if (mounted) setState(() => _showOverlay = false);
      });
      _confettiTickController.repeat();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _confettiEmitting = false);
      });
    }

    if (widget.id != null && widget.id! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(comprobanteProvider.notifier).fetchComprobanteById(widget.id!);
      });
    }
  }

  void _tickConfetti() {
    if (!widget.fromSale || _canvasSize == Size.zero) return;

    final elapsed = _confettiTickController.lastElapsedDuration ?? Duration.zero;
    final dt = _prevElapsed == null
        ? 0.0
        : (elapsed - _prevElapsed!).inMicroseconds / 1e6;
    _prevElapsed = elapsed;
    final dtClamped = dt.clamp(0.0, 0.05);

    _confettiParticles.removeWhere((p) => p.isDead);
    for (final p in _confettiParticles) {
      p.update(dtClamped, _canvasSize.height);
    }

    if (_confettiEmitting) {
      _emitAccumulator += dtClamped;
      while (_emitAccumulator >= 0.04) {
        _emitAccumulator -= 0.04;
        for (int i = 0; i < 5; i++) {
          _confettiParticles.add(
            _ConfettiParticle.emit(_canvasSize.width, _confettiRand),
          );
        }
      }
    }

    if (!_confettiEmitting && _confettiParticles.isEmpty) {
      _confettiTickController.stop();
    }
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _checkController.dispose();
    _confettiTickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _canvasSize = MediaQuery.of(context).size;
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
                                style: GoogleFonts.nunito(
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
                                  style: GoogleFonts.nunito(
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
                              Expanded(child: _buildSendDropdown(ticketToShow, context)),
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
        // ── Overlay checkmark (cubre pantalla completa, incluye AppBar) ─
        if (_showOverlay)
          AnimatedBuilder(
            animation: _overlayController,
            builder: (context, _) {
              return Opacity(
                opacity: _overlayOpacity.value,
                child: Material(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _checkController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(130, 130),
                              painter: _CheckmarkPainter(
                                circleScale: _circleScale.value,
                                checkProgress: _checkProgress.value,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '¡Venta completada!',
                          style: GoogleFonts.roboto(
                            fontSize: 43,
                            fontWeight: FontWeight.bold,
                            color: ColorSchema.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'El comprobante fue registrado con éxito',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: ColorSchema.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        // ── Confetti (canvas pantalla completa, emisores en todo el ancho) ─
        if (widget.fromSale)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  _confettiParticles,
                  repaint: _confettiTickController,
                ),
              ),
            ),
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
            style: GoogleFonts.nunito(
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
            style: GoogleFonts.nunito(
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
    return _SplitButton(
      directIcon: directIcon,
      directIconWidget: directIconWidget,
      directLabel: directLabel,
      onDirectAction: onDirectAction,
      dropdownOptions: dropdownOptions,
      color: color ?? ColorSchema.primaryColor,
    );
  }

  Widget _buildSendDropdown(Ticket ticket, BuildContext context) {
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
        showCustomModal(
          context: context,
          child: FormSendWhatsapp(ticket: ticket),
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

    return _SplitButton(
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

// ── Split Button ─────────────────────────────────────────────────────────────

class _SplitButton extends StatefulWidget {
  final IconData directIcon;
  final Widget? directIconWidget;
  final String directLabel;
  final VoidCallback onDirectAction;
  final List<DropdownActionOption> dropdownOptions;
  final Color color;

  const _SplitButton({
    required this.directIcon,
    this.directIconWidget,
    required this.directLabel,
    required this.onDirectAction,
    required this.dropdownOptions,
    required this.color,
  });

  @override
  State<_SplitButton> createState() => _SplitButtonState();
}

class _SplitButtonState extends State<_SplitButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _chevronKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _closeDropdown();
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (widget.dropdownOptions.isEmpty) return;

    setState(() => _isOpen = true);
    _animController.forward();

    final renderBox = _chevronKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    final screenPadding = MediaQuery.of(context).padding;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _SplitDropdownOverlay(
        buttonOffset: offset,
        buttonSize: size,
        options: widget.dropdownOptions,
        animation: _animation,
        color: widget.color,
        onOptionSelected: _onOptionSelected,
        onClose: _closeDropdown,
        screenSize: screenSize,
        screenPadding: screenPadding,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _animController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _onOptionSelected(DropdownActionOption option) {
    _closeDropdown();
    option.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // Left: direct action
            Expanded(
              child: InkWell(
                onTap: widget.onDirectAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.directIconWidget ?? Icon(widget.directIcon, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.directLabel,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Divider
            if (widget.dropdownOptions.isNotEmpty)
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.4)),
            // Right: chevron / dropdown trigger
            if (widget.dropdownOptions.isNotEmpty)
              InkWell(
                key: _chevronKey,
                onTap: _toggleDropdown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SplitDropdownOverlay extends StatelessWidget {
  final Offset buttonOffset;
  final Size buttonSize;
  final List<DropdownActionOption> options;
  final Animation<double> animation;
  final Color color;
  final ValueChanged<DropdownActionOption> onOptionSelected;
  final VoidCallback onClose;
  final Size screenSize;
  final EdgeInsets screenPadding;

  const _SplitDropdownOverlay({
    required this.buttonOffset,
    required this.buttonSize,
    required this.options,
    required this.animation,
    required this.color,
    required this.onOptionSelected,
    required this.onClose,
    required this.screenSize,
    required this.screenPadding,
  });

  @override
  Widget build(BuildContext context) {
    const dropdownWidth = 180.0;
    const itemHeight = 48.0;
    final dropdownHeight = options.length * itemHeight;

    double left = buttonOffset.dx + buttonSize.width - dropdownWidth;
    double top = buttonOffset.dy + buttonSize.height + 4;

    if (left < 16) left = 16;
    if (left + dropdownWidth > screenSize.width - 16) {
      left = screenSize.width - dropdownWidth - 16;
    }
    if (top + dropdownHeight > screenSize.height - screenPadding.bottom - 16) {
      top = buttonOffset.dy - dropdownHeight - 4;
    }

    return GestureDetector(
      onTap: onClose,
      behavior: HitTestBehavior.translucent,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Transform.scale(
                  scale: animation.value,
                  alignment: Alignment.topRight,
                  child: Opacity(opacity: animation.value, child: child),
                ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  shadowColor: Colors.black26,
                  child: SizedBox(
                    width: dropdownWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: options.map((opt) => InkWell(
                        onTap: () => onOptionSelected(opt),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(opt.icon, size: 20,
                                  color: opt.iconColor ?? color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opt.label,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom confetti ──────────────────────────────────────────────────────────

class _ConfettiParticle {
  Offset position;
  Offset velocity;
  final Color color;
  final double w;
  final double h;
  double angle;
  final double spin;
  bool _dead = false;

  _ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.w,
    required this.h,
    required this.angle,
    required this.spin,
  });

  static const _kColors = [
    Color(0xFF2ECC71),
    ColorSchema.primaryColor,
    Color(0xFFF1C40F),
    Color(0xFFE67E22),
    Colors.green,
    Colors.lightBlueAccent,
  ];

  /// Emite una partícula desde una posición aleatoria a lo largo del ancho.
  factory _ConfettiParticle.emit(double canvasWidth, Random rand) {
    // Abanico hacia abajo: ángulo entre 45° y 135° (todos apuntan hacia el body)
    final a = pi / 4 + rand.nextDouble() * pi / 2;
    final speed = 180.0 + rand.nextDouble() * 280.0;
    return _ConfettiParticle(
      position: Offset(rand.nextDouble() * canvasWidth, -12.0),
      velocity: Offset(cos(a) * speed, sin(a) * speed),
      color: _kColors[rand.nextInt(_kColors.length)],
      w: 10.0 + rand.nextDouble() * 10.0,
      h: 6.0 + rand.nextDouble() * 6.0,
      angle: rand.nextDouble() * 2 * pi,
      spin: (rand.nextDouble() - 0.5) * 8.0,
    );
  }

  void update(double dt, double canvasHeight) {
    velocity = Offset(velocity.dx * 0.99, velocity.dy + 380.0 * dt);
    position += velocity * dt;
    angle += spin * dt;
    if (position.dy > canvasHeight + 30) _dead = true;
  }

  bool get isDead => _dead;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles, {required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.angle);
      paint.color = p.color;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ── Checkmark ────────────────────────────────────────────────────────────────

class _CheckmarkPainter extends CustomPainter {
  final double circleScale;
  final double checkProgress;

  const _CheckmarkPainter({
    required this.circleScale,
    required this.checkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * circleScale;

    // Círculo verde
    final circlePaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // Aro interior translúcido
    if (circleScale > 0.1) {
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius - 6, ringPaint);
    }

    // Checkmark dibujado progresivamente
    if (checkProgress > 0 && circleScale > 0.4) {
      final checkPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final p1 = Offset(size.width * 0.22, size.height * 0.52);
      final p2 = Offset(size.width * 0.43, size.height * 0.68);
      final p3 = Offset(size.width * 0.78, size.height * 0.34);

      final seg1Len = (p2 - p1).distance;
      final seg2Len = (p3 - p2).distance;
      final totalLen = seg1Len + seg2Len;
      final drawLen = checkProgress * totalLen;

      final path = Path()..moveTo(p1.dx, p1.dy);
      if (drawLen <= seg1Len) {
        final t = drawLen / seg1Len;
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        path.lineTo(p2.dx, p2.dy);
        final t = ((drawLen - seg1Len) / seg2Len).clamp(0.0, 1.0);
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * t,
          p2.dy + (p3.dy - p2.dy) * t,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.circleScale != circleScale || old.checkProgress != checkProgress;
}
