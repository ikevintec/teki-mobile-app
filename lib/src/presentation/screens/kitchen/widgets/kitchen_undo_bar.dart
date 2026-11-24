import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_provider.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';

class KitchenUndoBar extends ConsumerWidget {
  final KitchenUndoAction? action;

  const KitchenUndoBar({super.key, required this.action});

  String _label(KitchenUndoAction value) {
    final subject = value.itemIds.length > 1
        ? '${value.itemIds.length} platos'
        : value.itemName;
    final status = switch (value.newStatus) {
      'PREPARACION' => 'en preparación',
      'PREPARADO' => 'listo',
      'DESPACHADO' => 'servido',
      _ => 'actualizado',
    };
    return '$subject · $status';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: action == null
          ? const SizedBox.shrink()
          : SafeArea(
              key: ValueKey('${action!.commandId}-${action!.newStatus}'),
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4ADE80),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _label(action!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: ref
                          .read(kitchenProvider.notifier)
                          .undoLastChange,
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text('Deshacer'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
