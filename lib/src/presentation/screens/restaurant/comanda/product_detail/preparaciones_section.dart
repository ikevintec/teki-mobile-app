import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail/detail_sheet_components.dart';
import 'package:teki_app/src/utils/constants.dart';

// ---------------------------------------------------------------------------
// Sección "Preparaciones" del sheet de detalle de producto
// ---------------------------------------------------------------------------

class PreparacionesSection extends StatelessWidget {
  final Product product;

  /// preparacionId -> opciones marcadas. Para preparaciones de selección
  /// única el set tiene como máximo un elemento.
  final Map<int, Set<int>> prepSelections;

  /// Se invoca al tocar una opción; el padre decide (vía
  /// `ComandaItemForm.togglePreparacion`) si marca, desmarca o reemplaza.
  final void Function(int prepId, int opcionId, bool seleccionMultiple)
  onToggle;

  const PreparacionesSection({
    super.key,
    required this.product,
    required this.prepSelections,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final preps = product.preparaciones ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Preparaciones'),
        ...preps.map((pp) {
          final prep = pp.preparacion;
          final prepId = prep?.id;
          final opciones = prep?.opciones ?? [];
          final multiple = prep?.seleccionMultiple == true;
          final selected = prepSelections[prepId] ?? const <int>{};

          final tiles = opciones.map<Widget>((op) {
            final opId = op.id;
            final title = Text(
              op.opcion ?? '',
              style: const TextStyle(fontSize: 13),
            );
            if (prepId == null || opId == null) {
              return ListTile(
                dense: true,
                visualDensity: kOptionTileDensity,
                contentPadding: kOptionTilePadding,
                title: title,
              );
            }
            if (multiple) {
              return CheckboxListTile(
                dense: true,
                visualDensity: kOptionTileDensity,
                contentPadding: kOptionTilePadding,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: ColorSchema.primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                value: selected.contains(opId),
                title: title,
                onChanged: (_) => onToggle(prepId, opId, true),
              );
            }
            return RadioListTile<int>(
              dense: true,
              visualDensity: kOptionTileDensity,
              contentPadding: kOptionTilePadding,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              toggleable: true,
              activeColor: ColorSchema.primaryColor,
              value: opId,
              title: title,
            );
          }).toList();

          return SectionCard(
            title: prep?.nombre ?? '',
            isRequired: pp.requerido == true,
            child: multiple
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 2),
                        child: Text(
                          'Puedes elegir varias opciones',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      ...tiles,
                    ],
                  )
                // Radio "toggleable": tocar la opción ya elegida la desmarca
                // (RadioGroup entrega null), igual que la web.
                : RadioGroup<int>(
                    groupValue: selected.isEmpty ? null : selected.first,
                    onChanged: (v) {
                      if (prepId == null) return;
                      final target =
                          v ?? (selected.isEmpty ? null : selected.first);
                      if (target != null) onToggle(prepId, target, false);
                    },
                    child: Column(children: tiles),
                  ),
          );
        }),
      ],
    );
  }
}
