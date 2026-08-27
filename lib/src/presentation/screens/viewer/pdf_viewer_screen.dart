// lib/src/presentation/screens/pdf/pdf_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/printer/ble_printer.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/shared/services/printer/printer_service.dart';
import 'package:teki_app/src/shared/services/pdf_file_service.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/constants.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String? uuid;
  final String fileName;
  final String? fileSize;
  final int? ticketId;

  /// URL completa del PDF. Si se provee, se usa en lugar de construir
  /// la URL a partir de [uuid]/[fileName] (caso de cotizaciones, que
  /// usan un endpoint distinto al de tickets).
  final String? customPdfUrl;

  /// Si es false, se oculta por completo la UI de impresión física
  /// (banner de advertencia y botón de imprimir). Usado por cotizaciones,
  /// que no se imprimen por impresora física.
  final bool allowPrint;

  const PdfViewerScreen({
    super.key,
    this.uuid,
    required this.fileName,
    this.fileSize = 'A4',
    this.ticketId,
    this.customPdfUrl,
    this.allowPrint = true,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final ComprobantePrintService _printService = ComprobantePrintService();
  final PdfFileService _pdfFileService = PdfFileService();
  bool _isPrinting = false;
  bool _isDownloading = false;

  String get _pdfUrl {
    if (widget.customPdfUrl != null) return widget.customPdfUrl!;
    final domain = Environment.apiUrl;
    // fileSize puede llegar null explícito desde un caller (pisa el default
    // del constructor); sin el fallback la URL interpolaría "tipo=null".
    return '$domain/public/pdf/tickets/${widget.uuid}/${widget.fileName}?tipo=${widget.fileSize ?? 'A4'}';
  }

  Future<void> _handlePrint() async {
    final session = ref.read(sesionProvider);

    if ((session.config?.tipoImpresionMovil ?? 'COFFE') == 'BLUETOOTH_BLE') {
      await _handlePrintBle();
      return;
    }

    final printer = session.saleStation?.impresoraComprobante;
    final escPos = session.config?.imprimeTicketsEscPos ?? false;
    final officeCode = session.office?.codigo ?? '';
    final idCompany = session.companySelected?.id;

    if (printer == null) return;
    if (widget.ticketId == null && escPos) return;

    setState(() => _isPrinting = true);
    try {
      final result = await _printService.printComprobante(
        ticketId: widget.ticketId ?? 0,
        pdfUrl: _pdfUrl,
        printer: printer,
        escPos: escPos,
        officeCode: officeCode,
        idCompany: idCompany,
      );
      if (result.printed) {
        successNotification('Comprobante impreso correctamente.');
      } else {
        warningNotification(
          result.message ?? 'No se pudo confirmar la impresión.',
          duration: const Duration(seconds: 4),
        );
      }
    } on PrintCoffeException catch (e) {
      errorNotification(e.message);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  /// Impresión local por Bluetooth BLE (tipoImpresionMovil = BLUETOOTH_BLE).
  Future<void> _handlePrintBle() async {
    final blePrinter = ref.read(blePrinterProvider).savedPrinter;
    if (blePrinter == null) {
      warningNotification('Configure una impresora Bluetooth en Configuración → Impresoras.');
      return;
    }
    if ((widget.ticketId ?? 0) <= 0) return;

    setState(() => _isPrinting = true);
    try {
      final result = await _printService.printComprobanteBle(
        ticketId: widget.ticketId!,
        printerService: ref.read(printerServiceProvider),
        blePrinter: blePrinter,
      );
      if (result.printed) {
        successNotification('Comprobante impreso correctamente.');
      } else {
        warningNotification(
          result.message ?? 'No se pudo confirmar la impresión.',
          duration: const Duration(seconds: 4),
        );
      }
    } on PrinterException catch (e) {
      errorNotification(e.message);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  /// Descarga el PDF localmente y abre el diálogo nativo de guardado,
  /// que funciona igual en Android (SAF) y en iOS (Files).
  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      final path = await _pdfFileService.downloadToTemp(
        url: _pdfUrl,
        fileName: widget.fileName,
      );
      final saved = await _pdfFileService.saveToDevice(path, fileName: widget.fileName);
      if (saved) successNotification('Comprobante guardado.');
    } on PdfFileException catch (e) {
      errorNotification(e.message);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sesionProvider);
    final clienteImpresion = session.config?.clienteImpresion;
    final printer = session.saleStation?.impresoraComprobante;
    final isBle = (session.config?.tipoImpresionMovil ?? 'COFFE') == 'BLUETOOTH_BLE';
    final canPrint = widget.allowPrint &&
        (isBle
            ? ref.watch(blePrinterProvider).hasPrinter && widget.ticketId != null
            : clienteImpresion == 'COFFE' && printer != null);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Comprobante - ${widget.fileName}",
        ),
      ),
      body: Column(
        children: [
          _buildActionButtons(
            canPrint,
            isBle ? ref.watch(blePrinterProvider).savedPrinter?.name : printer?.nombre,
            isBle: isBle,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SfPdfViewer.network(
                _pdfUrl,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                canShowPageLoadingIndicator: true,
                pageSpacing: 10,
                initialZoomLevel: 0.0,
                enableDoubleTapZooming: true,
                enableDocumentLinkAnnotation: true,
                enableTextSelection: true,
                enableHyperlinkNavigation: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool canPrint, String? printerName, {bool isBle = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          if (widget.allowPrint && !canPrint)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isBle
                          ? 'Configure una impresora Bluetooth en Configuración → Impresoras para imprimir el comprobante.'
                          : 'Configure una impresora en la estación de venta para imprimir el comprobante.',
                      style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (canPrint) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _handlePrint,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.print, size: 18),
                    label: Text('Imprimir en $printerName'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorSchema.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _handleDownload,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download, size: 18),
                label: const Text('Descargar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
