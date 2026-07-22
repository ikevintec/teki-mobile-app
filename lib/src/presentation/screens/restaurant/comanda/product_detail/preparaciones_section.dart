import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail/detail_sheet_components.dart';
import 'package:teki_app/src/utils/constants.dart';

// ---------------------------------------------------------------------------
// Sección "Preparaciones" del sheet de detalle de producto
// ---------------------------------------------------------------------------

class PreparacionesSection extends StatelessWidget {
  final Product product;

  /// preparacionId -> opcionId
  final Map<int, int?> prepSelections;
  final void Function(int prepId, int? opcionId) onSelected;

  const PreparacionesSection({
    super.key,
    required this.product,
    required this.prepSelections,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final preps = product.preparaciones ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Preparaciones'),
        ...preps.map((pp) {
          final opciones = pp.preparacion?.opciones ?? [];
          return SectionCard(
            title: pp.preparacion?.nombre ?? '',
            isRequired: pp.requerido == true,
            child: Column(
              children: opciones.map<Widget>((op) {
                return RadioListTile<int>(
                  dense: true,
                  activeColor: ColorSchema.primaryColor,
                  value: op.id ?? -1,
                  groupValue: prepSelections[pp.preparacion?.id],
                  title: Text(
                    op.opcion ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onChanged: (v) => onSelected(pp.preparacion!.id!, v),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}
