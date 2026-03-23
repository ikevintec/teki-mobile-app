import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/restaurant/cobrador_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class CobradorFilterBar extends ConsumerWidget {
  final int pvId;

  const CobradorFilterBar({super.key, required this.pvId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cobradorProvider);
    final notifier = ref.read(cobradorProvider.notifier);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _DateDropdown(
              state: state,
              pvId: pvId,
              notifier: notifier,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _FilterDropdown<TipoPedidoFilter>(
              label: 'Tipo',
              value: state.tipoPedidoFilter,
              items: TipoPedidoFilter.values,
              itemLabel: (f) => f.label,
              onChanged: (f) => notifier.setTipoPedido(f, pvId),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _FilterDropdown<bool>(
              label: 'Estado',
              value: state.pagado,
              items: const [false, true],
              itemLabel: (v) => v ? 'Pagados' : 'Pendientes',
              onChanged: (v) => notifier.setPagado(v, pvId),
            ),
          ),
          const SizedBox(width: 4),
          _ReloadButton(
            isLoading: state.isLoading,
            onTap: () => notifier.init(pvId),
          ),
        ],
      ),
    );
  }
}

class _DateDropdown extends StatelessWidget {
  final CobradorState state;
  final int pvId;
  final CobradorNotifier notifier;

  const _DateDropdown(
      {required this.state, required this.pvId, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: _FilterShell(
        label: 'Fecha',
        highlighted: true,
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 13, color: ColorSchema.primaryColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                _formatDate(state.selectedDate),
                style: const TextStyle(
                  fontSize: 13,
                  color: ColorSchema.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down,
                size: 18, color: ColorSchema.primaryColor),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'PE'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: ColorSchema.primaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) notifier.setDate(picked, pvId);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FilterShell(
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _FilterShell extends StatelessWidget {
  final String label;
  final Widget child;
  final bool highlighted;

  const _FilterShell({
    required this.label,
    required this.child,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: highlighted ? ColorSchema.primaryColor : Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: highlighted
                ? ColorSchema.primaryColor.withValues(alpha: 0.06)
                : Colors.grey.shade50,
            border: Border.all(
              color: highlighted
                  ? ColorSchema.primaryColor
                  : Colors.grey.shade300,
              width: highlighted ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ReloadButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _ReloadButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        SizedBox(
          width: 34,
          height: 34,
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(
                      color: ColorSchema.primaryColor, strokeWidth: 2),
                )
              : InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorSchema.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: ColorSchema.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.refresh,
                        color: ColorSchema.primaryColor, size: 18),
                  ),
                ),
        ),
      ],
    );
  }
}
