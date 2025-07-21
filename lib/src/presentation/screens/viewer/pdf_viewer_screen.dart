// lib/src/presentation/screens/pdf/pdf_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/utils/contstants.dart';

class PdfViewerScreen extends StatelessWidget {
  final String uuid;
  final String fileName;
  final String? fileSize;

  const PdfViewerScreen({
    super.key,
    required this.uuid,
    required this.fileName,
    this.fileSize = 'A4',
  });

  @override
  Widget build(BuildContext context) {
    final String domain = Environment.apiUrl;
    final String url =
        '$domain/public/pdf/tickets/$uuid/$fileName?tipo=$fileSize';
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Comprobante - $fileName",
        ),
      ),
      body: Container(
        margin:
            const EdgeInsets.all(16), // Espaciado de 16 px en todos los lados
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SfPdfViewer.network(
          url,
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
    );
  }
}
