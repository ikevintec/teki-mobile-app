import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/group.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail/detail_sheet_components.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

// ---------------------------------------------------------------------------
// Sección "Adicionales" (grupos de opciones) del sheet de detalle de producto.
// Muta los mapas de selección/cantidad recibidos y notifica vía [onChanged].
// ---------------------------------------------------------------------------

class GruposSection extends StatelessWidget {
  final Product product;

  /// grupoId -> `Set<opcionId>`
  final Map<int, Set<int>> groupSelections;

  /// grupoId -> opcionId -> cantidad (solo para grupos con permitirCantidad=true)
  final Map<int, Map<int, int>> groupQuantities;
  final VoidCallback onChanged;

  const GruposSection({
    super.key,
    required this.product,
    required this.groupSelections,
    required this.groupQuantities,
    required this.onChanged,
  });

  String? _grupoSubtitle(Group g) {
    final min = g.forzarMinimo;
    final max = g.forzarMaximo;
    if (min != null && max != null && min == max) {
      return 'Elige $min';
    } else if (min != null && max != null) {
      return 'Elige entre $min y $max';
    } else if (max != null) {
      return 'Máximo $max';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = product.grupos ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Adicionales'),
        ...grupos.map((g) {
          final opciones = g.opciones ?? [];
          final selected = groupSelections[g.id] ?? {};
          final allowQty = g.permitirCantidad == true;
          final maxSelect = g.forzarMaximo;

          return SectionCard(
            title: g.etiqueta ?? g.nombre ?? '',
            isRequired: g.requerido == true,
            subtitle: _grupoSubtitle(g),
            child: Column(
              children: opciones.map<Widget>((op) {
                final isChecked = selected.contains(op.id);
                final qty =
                    allowQty ? (groupQuantities[g.id]?[op.id] ?? 0) : 0;
                final priceLabel = (op.precio ?? 0) > 0
                    ? '+${formatExchange(moneda: product.moneda ?? 'PEN')}${(op.precio ?? 0).toStringAsFixed(2)}'
                    : null;

                if (allowQty) {
                  // Stepper row for permitirCantidad groups
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(op.nombre ?? '',
                                  style: const TextStyle(fontSize: 13)),
                              if (priceLabel != null)
                                Text(
                                  priceLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ColorSchema.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Stepper
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CompactStepButton(
                              icon: Icons.remove_rounded,
                              enabled: qty > 0,
                              onTap: () {
                                if (qty <= 1) {
                                  groupSelections[g.id!]!.remove(op.id!);
                                  groupQuantities[g.id]?.remove(op.id);
                                } else {
                                  groupQuantities[g.id!]![op.id!] = qty - 1;
                                }
                                onChanged();
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '$qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            CompactStepButton(
                              icon: Icons.add_rounded,
                              enabled: true,
                              onTap: () {
                                groupSelections[g.id!]!.add(op.id!);
                                groupQuantities.putIfAbsent(
                                    g.id!, () => {})[op.id!] = qty + 1;
                                onChanged();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else {
                  // Checkbox for regular groups, with forzarMaximo enforcement
                  final atMax = maxSelect != null &&
                      selected.length >= maxSelect &&
                      !isChecked;
                  // forzarMaximo == 1 behaves like radio (auto-deselect previous)
                  final isRadioStyle = maxSelect == 1;

                  return CheckboxListTile(
                    dense: true,
                    activeColor: ColorSchema.primaryColor,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: isChecked,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            op.nombre ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: atMax
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (priceLabel != null)
                          Text(
                            priceLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: atMax
                                  ? Colors.grey.shade400
                                  : ColorSchema.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    onChanged: atMax
                        ? null
                        : (v) {
                            if (v == true) {
                              if (isRadioStyle) {
                                groupSelections[g.id!]!.clear();
                              }
                              groupSelections[g.id!]!.add(op.id!);
                            } else {
                              groupSelections[g.id!]!.remove(op.id!);
                            }
                            onChanged();
                          },
                  );
                }
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}
