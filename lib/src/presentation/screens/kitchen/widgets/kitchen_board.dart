import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/kitchen/widgets/kitchen_order_card.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_provider.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_utils.dart';
import 'package:teki_app/src/utils/constants.dart';

class KitchenBoard extends ConsumerWidget {
  const KitchenBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kitchenProvider);
    final notifier = ref.read(kitchenProvider.notifier);
    final commands = kitchenCommandsForView(state);

    return Column(
      children: [
        _StatusTabs(state: state, onChanged: notifier.setView),
        _QuickFilters(
          state: state,
          onModeChanged: notifier.setMode,
          onClear: notifier.clearVisibleFilters,
        ),
        if (state.errorMessage != null && state.commands.isNotEmpty)
          _ErrorBanner(onRetry: notifier.refresh),
        Expanded(
          child: state.isLoading && state.commands.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: ColorSchema.primaryColor,
                    strokeWidth: 2,
                  ),
                )
              : RefreshIndicator(
                  color: ColorSchema.primaryColor,
                  onRefresh: notifier.refresh,
                  child: commands.isEmpty
                      ? _EmptyKitchen(
                          state: state,
                          onClear: notifier.clearVisibleFilters,
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 1180
                                ? 3
                                : constraints.maxWidth >= 720
                                ? 2
                                : 1;
                            const gap = 12.0;
                            final cardWidth =
                                (constraints.maxWidth -
                                    24 -
                                    (columns - 1) * gap) /
                                columns;
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                              children: [
                                Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  children: [
                                    for (final command in commands)
                                      SizedBox(
                                        width: cardWidth,
                                        child: KitchenOrderCard(
                                          key: ValueKey(command.id),
                                          command: command,
                                          state: state,
                                          onItemTap: notifier.advanceItem,
                                          onAdvanceAll: notifier.advanceAll,
                                          onCancellationsSeen:
                                              notifier.markCancellationsSeen,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final KitchenState state;
  final ValueChanged<KitchenView> onChanged;

  const _StatusTabs({required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Row(
          children: [
            for (final view in KitchenView.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: view == KitchenView.values.last ? 0 : 6,
                  ),
                  child: _StatusTab(
                    label: view.label,
                    color: kitchenViewColor(view),
                    count: kitchenCountForView(state, view),
                    selected: state.filters.view == view,
                    onTap: () => onChanged(view),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sin seleccionar: todos neutros (menos ruido). Seleccionado: su color.
    const neutral = Color(0xFF64748B);
    final foreground = selected ? Colors.white : neutral;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? color : const Color(0xFFF1F3F5),
            border: Border.all(
              color: selected ? color : const Color(0xFFE3E6EB),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  constraints: const BoxConstraints(minWidth: 17),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : neutral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  final KitchenState state;
  final ValueChanged<KitchenOrderMode> onModeChanged;
  final VoidCallback onClear;

  const _QuickFilters({
    required this.state,
    required this.onModeChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasAreas = state.filters.productionAreaIds.isNotEmpty;
    final canClear = hasAreas || state.filters.mode != KitchenOrderMode.all;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          if (canClear)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: Text(
                hasAreas
                    ? 'Limpiar (${state.filters.productionAreaIds.length})'
                    : 'Limpiar',
              ),
              style: TextButton.styleFrom(
                foregroundColor: ColorSchema.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          const Spacer(),
          _ModeSelector(mode: state.filters.mode, onChanged: onModeChanged),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final KitchenOrderMode mode;
  final ValueChanged<KitchenOrderMode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  static const _neutral = Color(0xFF64748B);

  String _shortLabel(KitchenOrderMode mode) => switch (mode) {
    KitchenOrderMode.all => 'Todos',
    KitchenOrderMode.dineIn => 'Aquí',
    KitchenOrderMode.takeaway => 'Llevar',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        border: Border.all(color: const Color(0xFFE3E6EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in KitchenOrderMode.values)
            _segment(option),
        ],
      ),
    );
  }

  Widget _segment(KitchenOrderMode option) {
    final selected = option == mode;
    return Material(
      color: selected ? ColorSchema.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onChanged(option),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Text(
            _shortLabel(option),
            style: TextStyle(
              color: selected ? Colors.white : _neutral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: const Color(0xFFFFF1F2),
      leading: const Icon(Icons.cloud_off_rounded, color: Color(0xFFB91C1C)),
      content: const Text(
        'No se pudo actualizar. Se reintentará automáticamente.',
      ),
      actions: [
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}

class _EmptyKitchen extends StatelessWidget {
  final KitchenState state;
  final VoidCallback onClear;

  const _EmptyKitchen({required this.state, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        state.filters.mode != KitchenOrderMode.all ||
        state.filters.productionAreaIds.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 70),
      children: [
        Icon(
          state.filters.view == KitchenView.cancelled
              ? Icons.block_rounded
              : Icons.task_alt_rounded,
          size: 72,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 18),
        Text(
          kitchenEmptyMessage(state.filters.view),
          textAlign: TextAlign.center,
          style: GoogleFonts.raleway(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        if (hasFilters) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Quitar filtros y ver todo'),
          ),
        ],
      ],
    );
  }
}
