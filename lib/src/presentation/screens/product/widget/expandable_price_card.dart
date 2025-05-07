import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:teki_app/src/data/models/productPrice.dart';
import 'package:teki_app/src/utils/formats.dart';

class ExpandablePriceCard extends HookWidget {
  final ProductPrice item;
  final int index;
  final List<Map<String, String>> tiposPrecioVenta;
  final Widget expandedContent;

  const ExpandablePriceCard({
    super.key,
    required this.item,
    required this.index,
    required this.tiposPrecioVenta,
    required this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => isExpanded.value = !isExpanded.value,
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nombre?.isNotEmpty == true
                          ? item.nombre!
                          : 'Sin nombre'),
                      Text(
                        'Tipo: ${tiposPrecioVenta.firstWhere(
                          (p) => p["value"] == item.tipoPrecio,
                          orElse: () => {"label": "Sin asignar"},
                        )["label"]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Precio: ${formatDouble(item.precio ?? 0.0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Utilidad: ${formatDouble(item.margenUtilidad ?? 0.0)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded.value
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 22,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: expandedContent,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
