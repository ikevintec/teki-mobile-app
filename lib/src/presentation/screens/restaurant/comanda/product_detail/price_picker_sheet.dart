import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

// ---------------------------------------------------------------------------
// Picker de precios de venta del producto (regular / especial / mayoreo)
// ---------------------------------------------------------------------------

void showProductPricePicker(
  BuildContext context, {
  required Product product,
  required double currentPrice,
  required ValueChanged<double> onSelected,
}) {
  final allPrices = product.preciosVenta ?? [];
  if (allPrices.isEmpty) return;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Precios disponibles',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Los precios de mayoreo se aplican automáticamente según la cantidad',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          ...allPrices.map((pp) {
            final isMayoreo = pp.tipoPrecio == 'MAYOREO';
            final isSelected = !isMayoreo && currentPrice == pp.precio;

            String label;
            String? sublabel;
            if (pp.tipoPrecio == 'POR_DEFECTO') {
              label = 'Precio regular';
            } else if (isMayoreo) {
              label = 'Mayoreo';
              final qty = (pp.unidadesMayoreo ?? 0).toStringAsFixed(0);
              sublabel = 'Desde $qty unidades · automático';
            } else {
              label = pp.nombre?.isNotEmpty == true
                  ? pp.nombre!
                  : 'Precio especial';
              sublabel = 'Especial';
            }

            return GestureDetector(
              onTap: isMayoreo
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      onSelected(pp.precio ?? 0);
                    },
              child: Opacity(
                opacity: isMayoreo ? 0.45 : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorSchema.primaryColor.withValues(alpha: 0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? ColorSchema.primaryColor
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isSelected
                                        ? ColorSchema.primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                                if (isMayoreo) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Auto',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.amber.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (sublabel != null)
                              Text(
                                sublabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${formatExchange(moneda: product.moneda ?? 'PEN')}${(pp.precio ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected
                              ? ColorSchema.primaryColor
                              : Colors.black87,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded,
                            color: ColorSchema.primaryColor, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}
