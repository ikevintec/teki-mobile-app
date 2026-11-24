import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';

// ---------------------------------------------------------------------------
// Sub-widgets reutilizables del sheet de detalle de producto
// ---------------------------------------------------------------------------

/// Densidad compacta para las filas de opciones (checkbox/radio) de
/// preparaciones y adicionales: ~32px por fila en vez de ~48px.
const VisualDensity kOptionTileDensity = VisualDensity(
  horizontal: -4,
  vertical: -4,
);
const EdgeInsets kOptionTilePadding = EdgeInsets.symmetric(horizontal: 8);

class InfoBox extends StatelessWidget {
  final Widget child;

  const InfoBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final bool isRequired;
  final String? subtitle;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.isRequired,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (isRequired) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Obligatorio',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Material transparente: los ListTile (radio/checkbox) pintan su
          // ripple sobre el Material más cercano; sin esto el fondo del
          // Container lo tapa (y en debug salta un assert).
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ],
      ),
    );
  }
}

class CompactStepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const CompactStepButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: enabled ? ColorSchema.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }
}
