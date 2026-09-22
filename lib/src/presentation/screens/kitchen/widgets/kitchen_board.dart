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

  IconData _icon(KitchenView view) => switch (view) {
    KitchenView.pending => Icons.schedule_rounded,
    KitchenView.ready => Icons.check_circle_outline_rounded,
    KitchenView.served => Icons.send_rounded,
    KitchenView.cancelled => Icons.block_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
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
                    icon: _icon(view),
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
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : ColorSchema.primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? ColorSchema.primaryColor
                : ColorSchema.primaryColor.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? ColorSchema.primaryColor
                  : ColorSchema.primaryColor.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 4),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.2)
                          : ColorSchema.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final mode in KitchenOrderMode.values)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: mode == KitchenOrderMode.values.last ? 0 : 7,
                    ),
                    child: _ModeButton(
                      label: mode.label,
                      selected: state.filters.mode == mode,
                      onTap: () => onModeChanged(mode),
                    ),
                  ),
                ),
            ],
          ),
          if (hasAreas || state.filters.mode != KitchenOrderMode.all) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text(
                hasAreas
                    ? 'Limpiar filtros (${state.filters.productionAreaIds.length})'
                    : 'Limpiar filtros',
              ),
              style: TextButton.styleFrom(
                foregroundColor: ColorSchema.primaryColor,
                backgroundColor: ColorSchema.primaryColor.withValues(
                  alpha: 0.08,
                ),
                side: BorderSide(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? ColorSchema.primaryColor
                : ColorSchema.primaryColor.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? ColorSchema.primaryColor
                  : ColorSchema.primaryColor.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.white : ColorSchema.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
