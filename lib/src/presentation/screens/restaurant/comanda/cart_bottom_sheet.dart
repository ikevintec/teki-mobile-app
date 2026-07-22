import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/restaurant/comanda_provider.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail_sheet.dart';
import 'package:teki_app/src/utils/constants.dart';

class CartBottomSheet extends ConsumerWidget {
  /// Parent screen context — needed for re-opening the product detail sheet
  /// after closing this sheet.
  final BuildContext parentContext;
  final void Function(CartItem item, int? index) onConfirm;

  const CartBottomSheet({
    super.key,
    required this.parentContext,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(comandaProvider).cartItems;
    final notifier = ref.read(comandaProvider.notifier);
    final totalItems = items.fold(0, (sum, i) => sum + i.quantity);
    final totalAmount = notifier.totalAmount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    color: ColorSchema.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Canasta',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '$totalItems producto(s)',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'S/ ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items list
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text(
                    'La canasta está vacía',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return _CartItemTile(
                    item: item,
                    onDelete: () => notifier.removeCartItem(index),
                    onEdit: () {
                      Navigator.pop(context);
                      showProductDetailSheet(
                        parentContext,
                        product: item.product,
                        existingItem: item,
                        cartIndex: index,
                        onConfirm: onConfirm,
                      );
                    },
                  );
                },
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart item tile
// ---------------------------------------------------------------------------

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _CartItemTile({
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _optionsSummary();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorSchema.primaryColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.nombre ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                if (summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      summary,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Row(
                  children: [
                    if (item.paraLlevar) ...[
                      Icon(Icons.takeout_dining_outlined,
                          size: 12, color: Colors.blue.shade400),
                      const SizedBox(width: 3),
                      Text(
                        'Para llevar',
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue.shade400),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (item.nota != null && item.nota!.isNotEmpty)
                      Expanded(
                        child: Text(
                          '"${item.nota}"',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Price + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorSchema.primaryColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    color: Colors.blue.shade500,
                    bgColor: Colors.blue.shade50,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
                    bgColor: Colors.red.shade50,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _optionsSummary() {
    final parts = <String>[];
    for (final prep in item.preparacionOpciones) {
      if (prep.nombreOpcion != null) {
        parts.add('${prep.nombrePreparacion ?? ''}: ${prep.nombreOpcion}');
      }
    }
    for (final grp in item.grupoOpciones) {
      if (grp.nombreOpcion != null) parts.add(grp.nombreOpcion!);
    }
    return parts.join(' · ');
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
