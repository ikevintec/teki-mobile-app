import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Widget reutilizable para escanear códigos de barras.
///
/// Uso:
/// ```dart
/// final codigo = await BarcodeScannerSheet.show(context);
/// if (codigo != null) { ... }
/// ```
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BarcodeScannerSheet(),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _lineController;
  late final Animation<double> _lineAnimation;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _lineController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanned = true;
    Navigator.of(context).pop(barcode!.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final sheetHeight = screenSize.height * 0.72;
    final frameWidth = screenSize.width * 0.72;
    final frameHeight = frameWidth * 0.5;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: sheetHeight,
        child: Stack(
          children: [
            // Cámara
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),

            // Overlay oscuro con recorte transparente
            CustomPaint(
              painter: _ScanOverlayPainter(
                frameWidth: frameWidth,
                frameHeight: frameHeight,
              ),
              child: const SizedBox.expand(),
            ),

            // Línea animada de escaneo
            AnimatedBuilder(
              animation: _lineAnimation,
              builder: (_, __) {
                final top = (sheetHeight / 2 - frameHeight / 2 - 20) +
                    _lineAnimation.value * (frameHeight - 4);
                return Positioned(
                  left: (screenSize.width - frameWidth) / 2 + 10,
                  right: (screenSize.width - frameWidth) / 2 + 10,
                  top: top,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: ColorSchema.primaryColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: ColorSchema.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Barra superior: cerrar + linterna
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (_, state, __) => _CircleButton(
                        icon: state.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        onTap: _controller.toggleTorch,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Instrucción inferior
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner,
                      color: Colors.white70, size: 22),
                  const SizedBox(height: 6),
                  const Text(
                    'Apunta al código de barras',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
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

// ─────────────────────────────────────────────
// Overlay: fondo oscuro con recorte + esquinas
// ─────────────────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  final double frameWidth;
  final double frameHeight;

  const _ScanOverlayPainter({
    required this.frameWidth,
    required this.frameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: center, width: frameWidth, height: frameHeight),
      const Radius.circular(12),
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(frame),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );

    canvas.drawRRect(
      frame,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _drawCorners(canvas, frame.outerRect);
  }

  void _drawCorners(Canvas canvas, Rect rect) {
    const len = 22.0;
    const r = 4.0;
    final paint = Paint()
      ..color = ColorSchema.primaryColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(rect.left + r, rect.top), Offset(rect.left + len, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top + r), Offset(rect.left, rect.top + len), paint);

    canvas.drawLine(Offset(rect.right - len, rect.top), Offset(rect.right - r, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top + r), Offset(rect.right, rect.top + len), paint);

    canvas.drawLine(Offset(rect.left + r, rect.bottom), Offset(rect.left + len, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom - len), Offset(rect.left, rect.bottom - r), paint);

    canvas.drawLine(Offset(rect.right - len, rect.bottom), Offset(rect.right - r, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom - len), Offset(rect.right, rect.bottom - r), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) =>
      old.frameWidth != frameWidth || old.frameHeight != frameHeight;
}

// ─────────────────────────────────────────────
// Botón circular para controles superpuestos
// ─────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
