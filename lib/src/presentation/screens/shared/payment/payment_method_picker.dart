import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/paymentMethod.dart';
import 'package:teki_app/src/utils/contstants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Componentes de pago compartidos.
//
// Reutilizados por el sheet de registro de pagos (cuentas por cobrar/pagar) y
// por el sheet de movimientos de caja (ingresos/egresos externos). Encapsulan
// la selección de método de pago, el input de monto por método, el badge de
// asignación y la decoración de inputs.
// ─────────────────────────────────────────────────────────────────────────────

/// Un método de pago seleccionado con su monto asignado editable.
class PaymentEntry {
  final PaymentMethod method;
  final TextEditingController amountController;

  PaymentEntry({required this.method, required double initialAmount})
      : amountController = TextEditingController(
            text: initialAmount > 0 ? initialAmount.toStringAsFixed(2) : '');

  void dispose() => amountController.dispose();
}

/// Decoración estándar de los inputs de los sheets de pago.
InputDecoration paymentInputDecoration({
  String? label,
  required String hint,
  String? prefix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.roboto(fontSize: 13, color: Colors.black54),
    hintText: hint,
    prefixText: prefix,
    hintStyle: GoogleFonts.roboto(color: Colors.black26, fontSize: 14),
    prefixStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ColorSchema.primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.grey[50],
  );
}

/// Badge que muestra el monto asignado vs total (o el cambio si aplica).
class AssignedBadge extends StatelessWidget {
  final double asignado;
  final double total;
  final String simbolo;
  final double cambio;

  const AssignedBadge({
    super.key,
    required this.asignado,
    required this.total,
    required this.simbolo,
    this.cambio = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (cambio > 0.005) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 13, color: Colors.green[700]!),
          const SizedBox(width: 4),
          Text(
            'Cambio: $simbolo${cambio.toStringAsFixed(2)}',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.green[700]!,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final exact = (asignado - total).abs() < 0.005;
    final over = asignado > total + 0.005;
    final color = exact
        ? Colors.green[700]!
        : over
            ? Colors.red[700]!
            : Colors.orange[700]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          exact ? Icons.check_circle_outline : Icons.info_outline,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$simbolo${asignado.toStringAsFixed(2)} / $simbolo${total.toStringAsFixed(2)}',
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Fila de método de pago: seleccionable, con input de monto cuando está activa.
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
  Color get _activeColor =>
      _isCash ? Colors.green.shade600 : ColorSchema.primaryColor;

  Widget _buildIcon() {
    const double size = 26;
    final url = method.imagenUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, e, s) => _fallbackIcon(size),
      );
    }
    return _fallbackIcon(size);
  }

  Widget _fallbackIcon(double size) => Icon(
        _isCash ? Icons.payments_rounded : Icons.credit_card_rounded,
        color: _isSelected ? _activeColor : Colors.grey.shade400,
        size: size,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              _isSelected ? _activeColor.withValues(alpha: 0.04) : Colors.white,
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
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: 26, child: Center(child: _buildIcon())),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      method.nombre ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            _isSelected ? _activeColor : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
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
                        : const SizedBox(key: ValueKey('empty'), width: 18),
                  ),
                ],
              ),
            ),
            if (_isSelected) ...[
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: _activeColor.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: entry!.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _activeColor,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          hintText: '0.00',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: Colors.black26),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: _activeColor.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: _activeColor, width: 1.5),
                          ),
                          filled: true,
                          fillColor: _activeColor.withValues(alpha: 0.03),
                        ),
                        onChanged: (_) => onAmountChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
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
