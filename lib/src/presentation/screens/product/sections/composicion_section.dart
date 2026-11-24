import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/screens/product/widget/product_picker_sheet.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Pestaña "Composición": muestra y edita los items (receta) de un paquete o
/// platillo producido — qué productos lo componen y en qué cantidad.
class ComposicionSection extends ConsumerWidget {
  const ComposicionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);
    final items = form.paqueteItems
        .asMap()
        .entries
        .where((e) => e.value.eliminado != true)
        .toList();

    return Container(
      color: Colors.white54,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: ListView(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Items del paquete',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: () async {
                  final p = await ProductPickerSheet.show(context,
                      titulo: 'Agregar item a la receta');
                  if (p != null) {
                    final ok = notifier.addPaqueteItem(p);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${p.nombre} ya está en la receta')));
                    }
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estos productos se consumen del inventario cuando se produce este paquete.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.layers_outlined,
                      size: 46, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text('Sin items en la receta',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          else
            ...items.map((entry) {
              final index = entry.key;
              final pi = entry.value;
              final cantidad = pi.cantidad ?? 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(pi.productoItem?.nombre ?? '-',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    _stepper(
                      cantidad,
                      (v) => notifier.setPaqueteItemCantidad(index, v),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                      onPressed: () => notifier.removePaqueteItem(index),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _stepper(double cantidad, ValueChanged<double> onChanged) {
    return Row(
      children: [
        _btn(Icons.remove, () {
          if (cantidad > 1) onChanged(cantidad - 1);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            cantidad == cantidad.roundToDouble()
                ? cantidad.toStringAsFixed(0)
                : cantidad.toString(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        _btn(Icons.add, () => onChanged(cantidad + 1)),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: ColorSchema.primaryColor),
      ),
    );
  }
}
