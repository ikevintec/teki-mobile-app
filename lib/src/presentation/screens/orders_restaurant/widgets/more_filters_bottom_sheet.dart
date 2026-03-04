import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class MoreFiltersBottomSheet extends StatefulWidget {
  final List<String> selectedEstados;
  final DateTime? desde;
  final DateTime? hasta;
  final void Function(List<String> estados, String? desde, String? hasta)
      onApply;

  const MoreFiltersBottomSheet({
    super.key,
    required this.selectedEstados,
    required this.onApply,
    this.desde,
    this.hasta,
  });

  @override
  State<MoreFiltersBottomSheet> createState() => _MoreFiltersBottomSheetState();

  static Future<void> show(
    BuildContext context, {
    required List<String> selectedEstados,
    DateTime? desde,
    DateTime? hasta,
    required void Function(
            List<String> estados, String? desde, String? hasta)
        onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MoreFiltersBottomSheet(
        selectedEstados: selectedEstados,
        desde: desde,
        hasta: hasta,
        onApply: onApply,
      ),
    );
  }
}

class _MoreFiltersBottomSheetState extends State<MoreFiltersBottomSheet> {
  late Set<String> _selected;
  DateTime? _desde;
  DateTime? _hasta;

  final _displayFormat = DateFormat('dd/MM/yyyy');
  final _apiFormat = DateFormat('dd-MM-yyyy');

  static const List<_EstadoOption> _options = [
    _EstadoOption('PENDIENTE', 'Pendiente', Colors.orange),
    _EstadoOption('PREPARADO', 'Preparado', Colors.blue),
    _EstadoOption('PRECUENTA', 'Pre-cuenta', Colors.purple),
    _EstadoOption('FINALIZADO', 'Finalizado', Colors.green),
    _EstadoOption('CANCELADO', 'Cancelado', Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedEstados);
    _desde = widget.desde;
    _hasta = widget.hasta;
  }

  void _toggleAll() {
    setState(() {
      if (_selected.length == kAllEstados.length) {
        _selected.clear();
      } else {
        _selected = Set.from(kAllEstados);
      }
    });
  }

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  Future<void> _pickDate({required bool isDesde}) async {
    final initial = isDesde
        ? (_desde ?? DateTime.now())
        : (_hasta ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorSchema.primaryColor,
              onPrimary: Colors.white,
              onSurface: ColorSchema.titleTextColor,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ColorSchema.primaryColor,
              ),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isDesde) {
        _desde = picked;
        // Si desde > hasta, resetear hasta
        if (_hasta != null && picked.isAfter(_hasta!)) _hasta = null;
      } else {
        _hasta = picked;
        // Si hasta < desde, resetear desde
        if (_desde != null && picked.isBefore(_desde!)) _desde = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            const Divider(height: 1),
            _buildDateSection(),
            const Divider(height: 1),
            _buildSelectAll(),
            const Divider(height: 1),
            ..._options.map(_buildOption),
            const SizedBox(height: 8),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: ColorSchema.primaryColor),
          const SizedBox(width: 8),
          const Text(
            'Más filtros',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: ColorSchema.titleTextColor,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              _selected.clear();
              _desde = null;
              _hasta = null;
            }),
            child: const Text(
              'Limpiar todo',
              style: TextStyle(color: ColorSchema.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rango de fechas',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: ColorSchema.subTitleTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateInputField(
                  label: 'Desde',
                  value: _desde != null ? _displayFormat.format(_desde!) : null,
                  onTap: () => _pickDate(isDesde: true),
                  onClear: _desde != null
                      ? () => setState(() => _desde = null)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateInputField(
                  label: 'Hasta',
                  value: _hasta != null ? _displayFormat.format(_hasta!) : null,
                  onTap: () => _pickDate(isDesde: false),
                  onClear: _hasta != null
                      ? () => setState(() => _hasta = null)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAll() {
    final allSelected = _selected.length == kAllEstados.length;
    return ListTile(
      leading: Checkbox(
        value: allSelected,
        tristate: _selected.isNotEmpty && !allSelected,
        activeColor: ColorSchema.primaryColor,
        onChanged: (_) => _toggleAll(),
      ),
      title: const Text(
        'Todos los estados',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: _toggleAll,
    );
  }

  Widget _buildOption(_EstadoOption option) {
    final isSelected = _selected.contains(option.value);
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        activeColor: ColorSchema.primaryColor,
        onChanged: (_) => _toggle(option.value),
      ),
      title: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(option.label),
        ],
      ),
      onTap: () => _toggle(option.value),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ColorSchema.primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancelar',
                  style: TextStyle(color: ColorSchema.primaryColor)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _selected.toList(),
                  _desde != null ? _apiFormat.format(_desde!) : null,
                  _hasta != null ? _apiFormat.format(_hasta!) : null,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child:
                  const Text('Aplicar', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateInputField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateInputField({
    required this.label,
    required this.onTap,
    this.value,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue
              ? ColorSchema.primaryColor.withValues(alpha: 0.06)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? ColorSchema.primaryColor.withValues(alpha: 0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: hasValue
                  ? ColorSchema.primaryColor
                  : ColorSchema.subTitleTextColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasValue
                      ? ColorSchema.titleTextColor
                      : ColorSchema.subTitleTextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: ColorSchema.subTitleTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EstadoOption {
  final String value;
  final String label;
  final Color color;

  const _EstadoOption(this.value, this.label, this.color);
}
