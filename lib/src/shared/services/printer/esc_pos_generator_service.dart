import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:teki_app/src/data/models/esc_pos/esc_pos_order.dart';

/// Genera bytes ESC/POS puros, sin conocer el transporte. El mismo resultado
/// puede enviarse por BLE hoy o por red/USB mañana.
///
/// Consume el mismo modelo [EscPosOrder] que hoy se serializa a JSON para el
/// servicio externo Coffe, de modo que un comprobante impreso por BLE sale
/// del mismo formateador que uno impreso por Coffe.
class EscPosGeneratorService {
  CapabilityProfile? _profile;

  Future<Generator> _generator(int paperWidthMm) async {
    _profile ??= await CapabilityProfile.load();
    final paper = paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80;
    return Generator(paper, _profile!);
  }

  /// Ticket mínimo de diagnóstico (sin imágenes a propósito).
  Future<List<int>> buildTestTicket({int paperWidthMm = 80}) async {
    final generator = await _generator(paperWidthMm);
    final separator = paperWidthMm == 58 ? '-' * 32 : '-' * 48;

    final bytes = <int>[
      ...generator.reset(),
      ...generator.text('TEKI',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
          linesAfter: 1),
      ...generator.text('PRUEBA DE IMPRESION',
          styles: const PosStyles(align: PosAlign.center, bold: true), linesAfter: 1),
      ...generator.text(separator),
      ...generator.text('Bluetooth BLE: OK'),
      ...generator.text('ESC/POS: OK'),
      ...generator.text(separator),
      ...generator.feed(1),
      ...generator.text('Impresion realizada correctamente',
          styles: const PosStyles(align: PosAlign.center)),
      ...generator.feed(4),
    ];
    return bytes;
  }

  /// Traduce la lista de órdenes (el mismo modelo que se envía a Coffe)
  /// a bytes ESC/POS. Las imágenes (logo) se omiten en esta primera versión:
  /// requieren descarga y rasterizado, y multiplican los bytes por BLE.
  Future<List<int>> buildFromOrders(
    List<EscPosOrder> orders, {
    int paperWidthMm = 80,
  }) async {
    final generator = await _generator(paperWidthMm);
    final bytes = <int>[...generator.reset()];

    // Segmentos TEXT con lineBreak=false se acumulan para emitirse como una
    // sola línea física (p. ej. etiqueta en negrita + valor normal).
    var pending = <EscPosOrderText>[];

    void flushLine() {
      if (pending.isEmpty) return;
      bytes.addAll(_buildTextLine(generator, pending, paperWidthMm));
      pending = [];
    }

    for (final order in orders) {
      switch (order.type) {
        case EscPosOrderType.TEXT:
          final text = order.text;
          if (text == null) break;
          pending.add(text);
          if (text.lineBreak == true) flushLine();
          break;
        case EscPosOrderType.FEED:
          flushLine();
          bytes.addAll(generator.feed(order.feed ?? 1));
          break;
        case EscPosOrderType.QR:
          flushLine();
          final value = order.qr?.value;
          if (value != null && value.isNotEmpty) {
            bytes.addAll(generator.qrcode(
              value,
              align: _mapAlign(order.qr?.justification),
              size: _mapQrSize(order.qr?.size),
            ));
          }
          break;
        case EscPosOrderType.IMAGE:
          // Sin soporte en la v1 BLE (ver doc de la clase).
          if (kDebugMode) debugPrint('[EscPos] IMAGE omitida en impresión BLE');
          break;
        case EscPosOrderType.DRAWER:
          flushLine();
          bytes.addAll(generator.drawer());
          break;
        case null:
          break;
      }
    }
    flushLine();
    return bytes;
  }

  // ---------------------------------------------------------------------------

  /// Emite una línea completa. Con un solo segmento delega en `text()`; con
  /// varios, escribe cada segmento con su estilo y cierra con salto de línea
  /// manual (Generator.text siempre agrega el salto, por eso no sirve aquí).
  List<int> _buildTextLine(Generator generator, List<EscPosOrderText> segments, int paperWidthMm) {
    final align = _mapAlign(
      segments.map((s) => s.style?.justification).firstWhere((j) => j != null, orElse: () => null),
    );

    if (segments.length == 1) {
      final seg = segments.single;
      return generator.text(
        _sanitize(seg.value ?? ''),
        styles: _mapStyles(seg.style).copyWith(align: align),
      );
    }

    final bytes = <int>[];
    for (final seg in segments) {
      bytes.addAll(generator.setStyles(_mapStyles(seg.style).copyWith(align: align)));
      bytes.addAll(latin1.encode(_sanitize(seg.value ?? '')));
    }
    bytes.add(0x0A);
    bytes.addAll(generator.setStyles(const PosStyles()));
    return bytes;
  }

  PosStyles _mapStyles(EscPosStyle? style) {
    if (style == null) return const PosStyles();
    final size = _mapTextSize(style.fontSize);
    return PosStyles(
      bold: style.bold ?? false,
      align: _mapAlign(style.justification),
      height: _mapTextSize(style.fontSizeY) ?? size ?? PosTextSize.size1,
      width: _mapTextSize(style.fontSizeX) ?? size ?? PosTextSize.size1,
    );
  }

  PosAlign _mapAlign(String? justification) {
    switch (justification) {
      case 'Center':
        return PosAlign.center;
      case 'Right':
        return PosAlign.right;
      default:
        return PosAlign.left;
    }
  }

  QRSize _mapQrSize(int? size) => QRSize((size ?? 4).clamp(1, 8));

  /// Los estilos de Coffe usan '_1'.._8' para el tamaño de fuente.
  PosTextSize? _mapTextSize(String? fontSize) {
    if (fontSize == null) return null;
    final n = int.tryParse(fontSize.replaceAll('_', ''));
    switch (n) {
      case 2:
        return PosTextSize.size2;
      case 3:
        return PosTextSize.size3;
      case 4:
        return PosTextSize.size4;
      case null:
      case 1:
        return PosTextSize.size1;
      default:
        return PosTextSize.size4;
    }
  }

  static const Map<String, String> _accents = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N',
    '°': 'o', '´': "'", '’': "'",
  };

  /// Las térmicas BLE genéricas arrancan en CP437, donde los acentos de
  /// latin1 salen como glifos incorrectos; se translitera a ASCII seguro.
  String _sanitize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? (rune > 0x7E ? '?' : char));
    }
    return buffer.toString();
  }
}
