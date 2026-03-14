// lib/src/presentation/screens/pdf/pdf_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/contstants.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String uuid;
  final String fileName;
  final String? fileSize;
  final int? ticketId;

  const PdfViewerScreen({
    super.key,
    required this.uuid,
    required this.fileName,
    this.fileSize = 'A4',
    this.ticketId,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final ComprobantePrintService _printService = ComprobantePrintService();
  bool _isPrinting = false;

  String get _pdfUrl {
    final domain = Environment.apiUrl;
    return '$domain/public/pdf/tickets/${widget.uuid}/${widget.fileName}?tipo=${widget.fileSize}';
  }

  Future<void> _handlePrint() async {
    final session = ref.read(sesionProvider);
    final printer = session.saleStation?.impresoraComprobante;
    final escPos = session.config?.imprimeTicketsEscPos ?? false;
    final officeCode = session.office?.codigo ?? '';
    final idCompany = session.companySelected?.id;

    if (printer == null) return;
    if (widget.ticketId == null && escPos) return;

    setState(() => _isPrinting = true);
    try {
      await _printService.printComprobante(
        ticketId: widget.ticketId ?? 0,
        pdfUrl: _pdfUrl,
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Comprobante - ${widget.fileName}",
        ),
      ),
      body: Column(
        children: [
          _buildPrintSection(canPrint, printer?.nombre),
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

  Widget _buildPrintSection(bool canPrint, String? printerName) {
    if (!canPrint) {
      return Container(
        margin: const EdgeInsets.all(16),
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
                'Configure una impresora en la estación de venta para imprimir el comprobante.',
                style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SizedBox(
        width: double.infinity,
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
    );
  }
}
