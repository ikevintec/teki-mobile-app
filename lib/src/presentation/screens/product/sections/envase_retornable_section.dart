import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/screens/product/widget/product_picker_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/presentation/widgets/switch/custom_switch.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Sección "Envase retornable": marca el producto como retornable y elige el
/// envase (ej. bidón vacío) que reingresa al inventario cuando el cliente
/// canjea. Espeja la web.
class EnvaseRetornableSection extends ConsumerWidget {
  const EnvaseRetornableSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo visible si la empresa habilitó el retorno de envases.
    final permite = ref.watch(sesionProvider).config?.permitirRetornoEnvase == true;
    if (!permite) return const SizedBox.shrink();
    final form = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: form.envaseRetornable
                ? ColorSchema.primaryColor.withValues(alpha: 0.4)
                : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recycling, size: 18, color: ColorSchema.primaryColor),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Envase retornable',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              CustomSwitch(
                title: '',
                value: form.envaseRetornable,
                onChanged: notifier.setEnvaseRetornable,
              ),
            ],
          ),
          if (form.envaseRetornable) ...[
            const SizedBox(height: 10),
            Text('Envase que reingresa al canjear',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            if (form.productoEnvase == null)
              OutlinedButton.icon(
                onPressed: () async {
                  final p = await ProductPickerSheet.show(context,
                      titulo: 'Elegir envase (ej. bidón vacío)');
                  if (p != null) notifier.setProductoEnvase(p);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Elegir envase'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(form.productoEnvase!.nombre ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                      onPressed: () => notifier.setProductoEnvase(null),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Al vender con canje reingresa 1 de este envase por unidad, y el costo será solo la diferencia.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}
