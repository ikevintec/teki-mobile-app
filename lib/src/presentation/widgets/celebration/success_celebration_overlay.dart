import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

/// Overlay de celebración (checkmark + confetti) que se muestra al
/// completar una venta o cotización. Encapsula su propia animación para
/// poder reutilizarse en distintas pantallas con título/subtítulo propios.
class SuccessCelebrationOverlay extends StatefulWidget {
  final bool show;
  final String title;
  final String subtitle;

  const SuccessCelebrationOverlay({
    super.key,
    required this.show,
    this.title = '¡Venta completada!',
    this.subtitle = 'El comprobante fue registrado con éxito',
  });

  @override
  State<SuccessCelebrationOverlay> createState() => _SuccessCelebrationOverlayState();
}

class _SuccessCelebrationOverlayState extends State<SuccessCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _overlayController;
  late final AnimationController _checkController;
  late final Animation<double> _overlayOpacity;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkProgress;
  bool _showOverlay = false;

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

    _confettiTickController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tickConfetti);

    if (widget.show) {
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
  }

  void _tickConfetti() {
    if (!widget.show || _canvasSize == Size.zero) return;

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

    if (!widget.show) return const SizedBox.shrink();

    return Stack(
      children: [
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
                          widget.title,
                          style: GoogleFonts.roboto(
                            fontSize: 43,
                            fontWeight: FontWeight.bold,
                            color: ColorSchema.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.roboto(
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

    final circlePaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    if (circleScale > 0.1) {
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius - 6, ringPaint);
    }

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
