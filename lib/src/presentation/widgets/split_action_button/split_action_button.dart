import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/dropdown_action_button/dropdown_action_button.dart';

/// Botón con una acción directa (icono + texto) y, opcionalmente, un
/// desplegable de opciones adicionales (chevron). Si [dropdownOptions]
/// está vacío, se muestra solo la acción directa sin chevron.
class SplitActionButton extends StatefulWidget {
  final IconData directIcon;
  final Widget? directIconWidget;
  final String directLabel;
  final VoidCallback onDirectAction;
  final List<DropdownActionOption> dropdownOptions;
  final Color color;

  const SplitActionButton({
    super.key,
    required this.directIcon,
    this.directIconWidget,
    required this.directLabel,
    required this.onDirectAction,
    required this.dropdownOptions,
    required this.color,
  });

  @override
  State<SplitActionButton> createState() => _SplitActionButtonState();
}

class _SplitActionButtonState extends State<SplitActionButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _chevronKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _closeDropdown();
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (widget.dropdownOptions.isEmpty) return;

    setState(() => _isOpen = true);
    _animController.forward();

    final renderBox = _chevronKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    final screenPadding = MediaQuery.of(context).padding;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _SplitDropdownOverlay(
        buttonOffset: offset,
        buttonSize: size,
        options: widget.dropdownOptions,
        animation: _animation,
        color: widget.color,
        onOptionSelected: _onOptionSelected,
        onClose: _closeDropdown,
        screenSize: screenSize,
        screenPadding: screenPadding,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _animController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _onOptionSelected(DropdownActionOption option) {
    _closeDropdown();
    option.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // Left: direct action
            Expanded(
              child: InkWell(
                onTap: widget.onDirectAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.directIconWidget ?? Icon(widget.directIcon, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.directLabel,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Divider
            if (widget.dropdownOptions.isNotEmpty)
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.4)),
            // Right: chevron / dropdown trigger
            if (widget.dropdownOptions.isNotEmpty)
              InkWell(
                key: _chevronKey,
                onTap: _toggleDropdown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SplitDropdownOverlay extends StatelessWidget {
  final Offset buttonOffset;
  final Size buttonSize;
  final List<DropdownActionOption> options;
  final Animation<double> animation;
  final Color color;
  final ValueChanged<DropdownActionOption> onOptionSelected;
  final VoidCallback onClose;
  final Size screenSize;
  final EdgeInsets screenPadding;

  const _SplitDropdownOverlay({
    required this.buttonOffset,
    required this.buttonSize,
    required this.options,
    required this.animation,
    required this.color,
    required this.onOptionSelected,
    required this.onClose,
    required this.screenSize,
    required this.screenPadding,
  });

  @override
  Widget build(BuildContext context) {
    const dropdownWidth = 180.0;
    const itemHeight = 48.0;
    final dropdownHeight = options.length * itemHeight;

    double left = buttonOffset.dx + buttonSize.width - dropdownWidth;
    double top = buttonOffset.dy + buttonSize.height + 4;

    if (left < 16) left = 16;
    if (left + dropdownWidth > screenSize.width - 16) {
      left = screenSize.width - dropdownWidth - 16;
    }
    if (top + dropdownHeight > screenSize.height - screenPadding.bottom - 16) {
      top = buttonOffset.dy - dropdownHeight - 4;
    }

    return GestureDetector(
      onTap: onClose,
      behavior: HitTestBehavior.translucent,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Transform.scale(
                  scale: animation.value,
                  alignment: Alignment.topRight,
                  child: Opacity(opacity: animation.value, child: child),
                ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  shadowColor: Colors.black26,
                  child: SizedBox(
                    width: dropdownWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: options.map((opt) => InkWell(
                        onTap: () => onOptionSelected(opt),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(opt.icon, size: 20,
                                  color: opt.iconColor ?? color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opt.label,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
