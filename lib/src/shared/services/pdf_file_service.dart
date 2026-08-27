import 'dart:ui' show Rect;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';

class PdfFileException implements Exception {
  final String message;
  PdfFileException(this.message);
}

/// Descarga PDFs del backend a un archivo local para poder compartirlos
/// (share sheet del sistema) o guardarlos (diálogo nativo de guardado),
/// en lugar de delegar en el navegador externo, que en Android no descarga.
class PdfFileService {
  final Dio _dio = ApiClient.dio;

  /// URL pública del PDF de un comprobante en formato [tipo] ('A4' | 'TICKET').
  static String ticketPdfUrl(String uuid, String identificador, String tipo) =>
      '${Environment.apiUrl}/public/pdf/tickets/$uuid/$identificador?tipo=$tipo';

  /// Descarga el PDF de [url] al directorio temporal como `[fileName].pdf`
  /// y devuelve la ruta local. Lanza [PdfFileException] si la descarga falla.
  Future<String> downloadToTemp({required String url, required String fileName}) async {
    final dir = await getTemporaryDirectory();
    final name = fileName.toLowerCase().endsWith('.pdf') ? fileName : '$fileName.pdf';
    final path = '${dir.path}/$name';
    try {
      await _dio.download(url, path);
    } catch (e) {
      if (kDebugMode) debugPrint('[PdfFile] Error descargando $url: $e');
      throw PdfFileException('No se pudo descargar el PDF del comprobante.');
    }
    return path;
  }

  /// Abre el share sheet del sistema con el archivo en [path].
  /// [sharePositionOrigin] es requerido por iPad para anclar el popover.
  Future<void> shareFile(String path, {Rect? sharePositionOrigin}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path, mimeType: 'application/pdf')],
      sharePositionOrigin: sharePositionOrigin,
    ));
  }

  /// Abre el diálogo nativo "guardar como" (SAF en Android, Files en iOS)
  /// para el archivo en [path]. Devuelve false si el usuario canceló.
  Future<bool> saveToDevice(String path, {required String fileName}) async {
    final name = fileName.toLowerCase().endsWith('.pdf') ? fileName : '$fileName.pdf';
    final savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: path,
        fileName: name,
        mimeTypesFilter: const ['application/pdf'],
      ),
    );
    return savedPath != null;
  }
}
