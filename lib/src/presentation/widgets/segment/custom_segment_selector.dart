import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';

class CustomSegmentedSelector extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool disabled; // Nuevo prop

  const CustomSegmentedSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.disabled = false, // Valor por defecto
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: disabled
                      ? ColorSchema.primaryColor.withOpacity(0.5)
                      : ColorSchema.primaryColor,
                  width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
                    final isSelected =
                        selected.toUpperCase() == option.toUpperCase();
                    final index = options.indexOf(option);

                    return Expanded(
                      child: GestureDetector(
                        onTap: disabled ? null : () => onChanged(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (disabled
                                    ? ColorSchema.primaryColor.withOpacity(0.5)
                                    : ColorSchema.primaryColor)
                                : Colors.transparent,
                            borderRadius: BorderRadius.horizontal(
                              left: index == 0
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                              right: index == options.length - 1
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (disabled
                                        ? ColorSchema.primaryColor
                                            .withOpacity(0.5)
                                        : ColorSchema.primaryColor),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomSegmentedSelectorMapped extends StatefulWidget {
  final String label;
  final List<Map<String, String>> dataSource;
  final String labelKey;
  final String valueKey;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool disabled; // Nuevo prop

  const CustomSegmentedSelectorMapped({
    super.key,
    required this.label,
    required this.dataSource,
    this.labelKey = 'label',
    this.valueKey = 'value',
    this.initialValue,
    this.onChanged,
    this.disabled = false, // Valor por defecto
  });

  @override
  State<CustomSegmentedSelectorMapped> createState() =>
      _CustomSegmentedSelectorMappedState();
}

class _CustomSegmentedSelectorMappedState
    extends State<CustomSegmentedSelectorMapped> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue ??
        (widget.dataSource.isNotEmpty
            ? widget.dataSource.first[widget.valueKey] ?? ''
            : '');
  }

  void handleSelect(String value) {
    setState(() {
      selectedValue = value;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> items = widget.dataSource;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Opacity(
          opacity: widget.disabled ? 0.99 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: widget.disabled
                      ? ColorSchema.primaryColor.withOpacity(0.7)
                      : ColorSchema.primaryColor,
                  width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final labelValue = item[widget.labelKey] ?? '';
                    final actualValue = item[widget.valueKey] ?? '';
                    final isSelected = selectedValue == actualValue;

                    return Expanded(
                      child: GestureDetector(
                        onTap: widget.disabled
                            ? null
                            : () => handleSelect(actualValue),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (widget.disabled
                                    ? ColorSchema.primaryColor.withOpacity(0.7)
                                    : ColorSchema.primaryColor)
                                : Colors.transparent,
                            borderRadius: BorderRadius.horizontal(
                              left: index == 0
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                              right: index == items.length - 1
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              labelValue,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (widget.disabled
                                        ? ColorSchema.primaryColor
                                            .withOpacity(0.7)
                                        : ColorSchema.primaryColor),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
