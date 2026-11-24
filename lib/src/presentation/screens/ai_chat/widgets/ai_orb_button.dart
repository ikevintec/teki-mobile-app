import 'package:flutter/material.dart';

/// Paleta Apple Intelligence usada por el asistente (misma de la web).
const kAiColors = [
  Color(0xFF0A84FF),
  Color(0xFFBF5AF2),
  Color(0xFFFF375F),
  Color(0xFFFF9F0A),
];

/// Orbe flotante del asistente: gradiente cónico giratorio + respiración,
/// espejo del .ai-orb de la web.
class AiOrbButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const AiOrbButton({super.key, required this.onTap, this.size = 56});

  @override
  State<AiOrbButton> createState() => _AiOrbButtonState();
}

class _AiOrbButtonState extends State<AiOrbButton>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _breathe]),
        builder: (context, _) {
          final scale = 1 + 0.05 * _breathe.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [...kAiColors, kAiColors.first],
                  transform:
                      GradientRotation(_spin.value * 2 * 3.14159265),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kAiColors[1].withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}
