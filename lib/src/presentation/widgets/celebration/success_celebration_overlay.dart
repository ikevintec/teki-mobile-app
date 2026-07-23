import 'dart:math';

import 'package:flutter/material.dart';

/// Check verde animado (círculo elástico + trazo del check) para mostrar
/// dentro del header de una pantalla de éxito. El confeti de
/// [SuccessCelebrationOverlay] revienta desde este widget si se le pasa
/// el mismo [GlobalKey] como ancla.
class AnimatedSuccessCheck extends StatefulWidget {
  final double size;

  const AnimatedSuccessCheck({super.key, this.size = 96});

  @override
  State<AnimatedSuccessCheck> createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<AnimatedSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _circleScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _checkProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _CheckmarkPainter(
          circleScale: _circleScale.value,
          checkProgress: _checkProgress.value,
        ),
      ),
    );
  }
}

/// Capa de confeti no bloqueante que revienta radialmente desde el centro
/// del widget anclado en [anchorKey] (p.ej. un [AnimatedSuccessCheck] en el
/// header). No pinta fondo ni textos: la pantalla queda visible y usable
/// desde el primer frame.
class SuccessCelebrationOverlay extends StatefulWidget {
  final bool show;

  /// Widget desde cuyo centro revienta el confeti. Si es null o aún no está
  /// montado, se usa un punto en la parte superior central de la pantalla.
  final GlobalKey? anchorKey;

  const SuccessCelebrationOverlay({
    super.key,
    required this.show,
    this.anchorKey,
  });

  @override
  State<SuccessCelebrationOverlay> createState() => _SuccessCelebrationOverlayState();
}

class _SuccessCelebrationOverlayState extends State<SuccessCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickController;
  final List<_ConfettiParticle> _particles = [];
  final Random _rand = Random();
  bool _emitting = false;
  double _emitElapsed = 0;
  double _emitAccumulator = 0;
  Duration? _prevElapsed;
  Size _canvasSize = Size.zero;
  Offset? _origin;

  // Ventana de emisión: ráfaga corta, tipo explosión.
  static const _kEmitWindow = 0.45; // segundos
  static const _kEmitInterval = 0.016;
  static const _kParticlesPerEmit = 7;

  @override
  void initState() {
    super.initState();
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);

    if (widget.show) {
      _emitting = true;
      // El ancla se resuelve después del primer frame, cuando el check ya
      // tiene posición en pantalla.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _origin = _resolveOrigin();
        _tickController.repeat();
      });
    }
  }

  Offset _resolveOrigin() {
    final anchorContext = widget.anchorKey?.currentContext;
    final box = anchorContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(box.size.center(Offset.zero));
    }
    // Fallback: parte superior central de la pantalla.
    return Offset(_canvasSize.width / 2, _canvasSize.height * 0.22);
  }

  void _tick() {
    if (_canvasSize == Size.zero || _origin == null) return;

    final elapsed = _tickController.lastElapsedDuration ?? Duration.zero;
    final dt = _prevElapsed == null
        ? 0.0
        : (elapsed - _prevElapsed!).inMicroseconds / 1e6;
    _prevElapsed = elapsed;
    final dtClamped = dt.clamp(0.0, 0.05);

    _particles.removeWhere((p) => p.isDead);
    for (final p in _particles) {
      p.update(dtClamped, _canvasSize.height);
    }

    if (_emitting) {
      _emitElapsed += dtClamped;
      _emitAccumulator += dtClamped;
      while (_emitAccumulator >= _kEmitInterval) {
        _emitAccumulator -= _kEmitInterval;
        for (int i = 0; i < _kParticlesPerEmit; i++) {
          _particles.add(_ConfettiParticle.burst(_origin!, _rand));
        }
      }
      if (_emitElapsed >= _kEmitWindow) _emitting = false;
    }

    if (!_emitting && _particles.isEmpty) {
      _tickController.stop();
    }
  }

  @override
  void dispose() {
    _tickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _canvasSize = MediaQuery.of(context).size;

    if (!widget.show) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(_particles, repaint: _tickController),
        ),
      ),
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
  final double lifetime; // segundos
  double _age = 0;
  bool _dead = false;

  _ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.w,
    required this.h,
    required this.angle,
    required this.spin,
    required this.lifetime,
  });

  static const _kColors = [
    Color(0xFF2ECC71),
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFFF1C40F),
    Color(0xFFE67E22),
    Colors.lightBlueAccent,
  ];

  /// Emite una partícula que revienta radialmente desde [origin],
  /// con sesgo hacia arriba (como confeti de fiesta).
  factory _ConfettiParticle.burst(Offset origin, Random rand) {
    // Ángulo en todo el círculo pero concentrado hacia arriba:
    // -PI/2 (arriba en coords de pantalla) ± una dispersión amplia.
    final a = -pi / 2 + (rand.nextDouble() - 0.5) * pi * 1.6;
    final speed = 160.0 + rand.nextDouble() * 380.0;
    return _ConfettiParticle(
      position: origin,
      velocity: Offset(cos(a) * speed, sin(a) * speed),
      color: _kColors[rand.nextInt(_kColors.length)],
      w: 8.0 + rand.nextDouble() * 8.0,
      h: 5.0 + rand.nextDouble() * 5.0,
      angle: rand.nextDouble() * 2 * pi,
      spin: (rand.nextDouble() - 0.5) * 10.0,
      lifetime: 1.4 + rand.nextDouble() * 1.0,
    );
  }

  void update(double dt, double canvasHeight) {
    velocity = Offset(velocity.dx * 0.985, velocity.dy + 520.0 * dt);
    position += velocity * dt;
    angle += spin * dt;
    _age += dt;
    if (_age >= lifetime || position.dy > canvasHeight + 30) _dead = true;
  }

  /// Se desvanece en el último 30% de su vida.
  double get opacity {
    final t = _age / lifetime;
    if (t < 0.7) return 1.0;
    return ((1.0 - t) / 0.3).clamp(0.0, 1.0);
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
      paint.color = p.color.withValues(alpha: p.opacity);
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
        ..strokeWidth = 7
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
