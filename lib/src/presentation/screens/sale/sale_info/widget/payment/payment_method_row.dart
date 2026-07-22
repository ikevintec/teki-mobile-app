import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment/payment_entry.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/utils/constants.dart';

// ─── Fila de método de pago con inputs expandibles ───────────────────────────

class PaymentMethodRow extends StatelessWidget {
  final PaymentMethod method;
  final PaymentEntry? entry;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final VoidCallback onAmountChanged;

  const PaymentMethodRow({
    super.key,
    required this.method,
    required this.entry,
    required this.onTap,
    required this.onAmountChanged,
    this.onRemove,
  });

  bool get _isSelected => entry != null;
  bool get _isCash => (method.formaPago ?? '').toUpperCase() == 'EFECTIVO';
  Color get _activeColor => _isCash ? Colors.green.shade600 : ColorSchema.primaryColor;

  Widget _buildIcon() {
    const double size = 28;
    final url = method.imagenUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, e, stack) => _fallbackIcon(size),
      );
    }
    return _fallbackIcon(size);
  }

  Widget _fallbackIcon(double size) => Icon(
        _isCash ? Icons.payments_rounded : Icons.credit_card_rounded,
        color: _isSelected ? _activeColor : Colors.grey.shade500,
        size: size,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _isSelected
              ? _activeColor.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isSelected ? _activeColor : Colors.grey.shade200,
            width: _isSelected ? 1.5 : 1,
          ),
          boxShadow: _isSelected
              ? [
                  BoxShadow(
                    color: _activeColor.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cabecera del método ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 26, child: Center(child: _buildIcon())),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      method.nombre ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _isSelected ? _activeColor : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isSelected
                        ? Container(
                            key: const ValueKey('check'),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _activeColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 11),
                          )
                        : const SizedBox(
                            key: ValueKey('empty'), width: 18),
                  ),
                ],
              ),
            ),
            // ── Inputs expandibles ────────────────────────────────────
            if (_isSelected) ...[
              Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: _activeColor.withValues(alpha: 0.2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFieldSection(
                        label: 'Monto',
                        hint: '0.00',
                        inputType: TextInputType.number,
                        controller: entry!.amountController,
                        onChanged: (_) => onAmountChanged(),
                        showDoneButton: true,
                      ),
                    ),
                    if (!_isCash) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFieldSection(
                          label: '# Operación',
                          hint: 'Número',
                          inputType: TextInputType.number,
                          controller: entry!.operationController,
                          showDoneButton: true,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
