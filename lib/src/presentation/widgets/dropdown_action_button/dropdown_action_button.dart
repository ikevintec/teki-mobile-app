import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:teki_app/src/utils/contstants.dart';

/// Model for dropdown action options
class DropdownActionOption {
  final String label;
  final IconData icon;
  final String? url;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final bool enabled;

  const DropdownActionOption({
    required this.label,
    required this.icon,
    this.url,
    this.onPressed,
    this.iconColor,
    this.enabled = true,
  });

  /// Creates a WhatsApp option
  static DropdownActionOption whatsapp({
    required String phoneNumber,
    String? message,
    bool enabled = true,
  }) {
    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';
    final whatsappUrl = 'https://wa.me/$phoneNumber${message != null ? '?text=$encodedMessage' : ''}';
    
    return DropdownActionOption(
      label: 'WhatsApp',
      icon: Icons.chat,
      url: whatsappUrl,
      iconColor: const Color(0xFF25D366),
      enabled: enabled && phoneNumber.isNotEmpty,
    );
  }

  /// Creates an Email option
  static DropdownActionOption email({
    required String emailAddress,
    String? subject,
    String? body,
    bool enabled = true,
  }) {
    final subjectParam = subject != null ? 'subject=${Uri.encodeComponent(subject)}' : '';
    final bodyParam = body != null ? 'body=${Uri.encodeComponent(body)}' : '';
    final params = [subjectParam, bodyParam].where((p) => p.isNotEmpty).join('&');
    final emailUrl = 'mailto:$emailAddress${params.isNotEmpty ? '?$params' : ''}';
    
    return DropdownActionOption(
      label: 'Email',
      icon: Icons.email,
      url: emailUrl,
      iconColor: const Color(0xFF1976D2),
      enabled: enabled && emailAddress.isNotEmpty,
    );
  }

  /// Creates a Phone option
  static DropdownActionOption phone({
    required String phoneNumber,
    bool enabled = true,
  }) {
    return DropdownActionOption(
      label: 'Llamar',
      icon: Icons.phone,
      url: 'tel:$phoneNumber',
      iconColor: const Color(0xFF4CAF50),
      enabled: enabled && phoneNumber.isNotEmpty,
    );
  }

}

/// A professional dropdown action button widget
class DropdownActionButton extends StatefulWidget {
  /// List of action options to display
  final List<DropdownActionOption> options;
  
  /// Main button label
  final String label;
  
  /// Main button icon
  final IconData icon;
  
  /// Button style variant
  final DropdownActionButtonStyle style;
  
  /// Whether the button is enabled
  final bool enabled;
  
  /// Custom button color (optional)
  final Color? buttonColor;
  
  /// Callback when dropdown is opened/closed
  final ValueChanged<bool>? onDropdownToggle;

  const DropdownActionButton({
    super.key,
    required this.options,
    this.label = 'Enviar',
    this.icon = Icons.send,
    this.style = DropdownActionButtonStyle.elevated,
    this.enabled = true,
    this.buttonColor,
    this.onDropdownToggle,
  });

  @override
  State<DropdownActionButton> createState() => _DropdownActionButtonState();
}

enum DropdownActionButtonStyle {
  elevated,
  outlined,
  text,
}

class _DropdownActionButtonState extends State<DropdownActionButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (!widget.enabled || widget.options.isEmpty) return;

    setState(() => _isDropdownOpen = true);
    widget.onDropdownToggle?.call(true);
    _animationController.forward();

    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenPadding = MediaQuery.of(context).padding;

    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay(
        buttonOffset: offset,
        buttonSize: size,
        options: widget.options.where((option) => option.enabled).toList(),
        animation: _animation,
        onOptionSelected: _onOptionSelected,
        onClose: _closeDropdown,
        screenSize: screenSize,
        screenPadding: screenPadding,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (!_isDropdownOpen) return;

    setState(() => _isDropdownOpen = false);
    widget.onDropdownToggle?.call(false);
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _onOptionSelected(DropdownActionOption option) {
    _closeDropdown();
    
    if (option.onPressed != null) {
      option.onPressed!.call();
    } else if (option.url != null && option.url!.isNotEmpty) {
      _launchUrl(option.url!);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('Cannot launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $url, Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidOptions = widget.options.any((option) => option.enabled);
    final isEnabled = widget.enabled && hasValidOptions;

    return GestureDetector(
      key: _buttonKey,
      onTap: isEnabled ? _toggleDropdown : null,
      child: _buildButton(context, isEnabled),
    );
  }

  Widget _buildButton(BuildContext context, bool isEnabled) {
    final color = widget.buttonColor ?? ColorSchema.primaryColor;
    
    switch (widget.style) {
      case DropdownActionButtonStyle.elevated:
        return _buildElevatedButton(color, isEnabled);
      case DropdownActionButtonStyle.outlined:
        return _buildOutlinedButton(color, isEnabled);
      case DropdownActionButtonStyle.text:
        return _buildTextButton(color, isEnabled);
    }
  }

  Widget _buildElevatedButton(Color color, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEnabled ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: _buildButtonContent(
        iconColor: isEnabled ? Colors.white : Colors.grey[600],
        textColor: isEnabled ? Colors.white : Colors.grey[600],
      ),
    );
  }

  Widget _buildOutlinedButton(Color color, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? color : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: _buildButtonContent(
        iconColor: isEnabled ? color : Colors.grey[600],
        textColor: isEnabled ? color : Colors.grey[600],
      ),
    );
  }

  Widget _buildTextButton(Color color, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _buildButtonContent(
        iconColor: isEnabled ? color : Colors.grey[600],
        textColor: isEnabled ? color : Colors.grey[600],
      ),
    );
  }

  Widget _buildButtonContent({
    required Color? iconColor,
    required Color? textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 18,
          color: iconColor,
        ),
      ],
    );
  }
}

class _DropdownOverlay extends StatelessWidget {
  final Offset buttonOffset;
  final Size buttonSize;
  final List<DropdownActionOption> options;
  final Animation<double> animation;
  final ValueChanged<DropdownActionOption> onOptionSelected;
  final VoidCallback onClose;
  final Size screenSize;
  final EdgeInsets screenPadding;

  const _DropdownOverlay({
    required this.buttonOffset,
    required this.buttonSize,
    required this.options,
    required this.animation,
    required this.onOptionSelected,
    required this.onClose,
    required this.screenSize,
    required this.screenPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate dropdown position with boundary constraints
    final dropdownSize = _calculateDropdownSize();
    final position = _calculateOptimalPosition(dropdownSize);
    
    return GestureDetector(
      onTap: onClose,
      behavior: HitTestBehavior.translucent,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: animation.value,
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: animation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildDropdownMenu(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Size _calculateDropdownSize() {
    // Estimate dropdown size based on options
    // const minWidth = 150.0;
    const maxWidth = 200.0;
    const itemHeight = 48.0; // padding + text height
    
    final height = options.length * itemHeight;
    return Size(maxWidth, height);
  }

  Offset _calculateOptimalPosition(Size dropdownSize) {
    const padding = 16.0; // Safe padding from screen edges
    
    // Default position (below button, aligned to left edge)
    double left = buttonOffset.dx;
    double top = buttonOffset.dy + buttonSize.height + 4;
    
    // Check right boundary
    if (left + dropdownSize.width > screenSize.width - padding) {
      // Align to right edge of button instead
      left = buttonOffset.dx + buttonSize.width - dropdownSize.width;
      
      // If still overflows, align to screen edge
      if (left < padding) {
        left = screenSize.width - dropdownSize.width - padding;
      }
    }
    
    // Check bottom boundary
    if (top + dropdownSize.height > screenSize.height - screenPadding.bottom - padding) {
      // Show above button instead
      top = buttonOffset.dy - dropdownSize.height - 4;
      
      // If still overflows at top, position within visible area
      if (top < screenPadding.top + padding) {
        top = screenPadding.top + padding;
      }
    }
    
    // Ensure minimum padding from left edge
    if (left < padding) {
      left = padding;
    }
    
    return Offset(left, top);
  }

  Widget _buildDropdownMenu(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      shadowColor: Colors.black26,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 150,
          maxWidth: 200,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => _buildOptionItem(option)).toList(),
        ),
      ),
    );
  }

  Widget _buildOptionItem(DropdownActionOption option) {
    return InkWell(
      onTap: () => onOptionSelected(option),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              option.icon,
              size: 20,
              color: option.iconColor ?? ColorSchema.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}