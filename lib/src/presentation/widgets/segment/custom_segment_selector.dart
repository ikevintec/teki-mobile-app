import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/contstants.dart';

class CustomSegmentedSelector extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const CustomSegmentedSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ColorSchema.primaryColor, width: 1),
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
                      onTap: () => onChanged(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorSchema.primaryColor
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
                                  : ColorSchema.primaryColor,
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

  const CustomSegmentedSelectorMapped({
    super.key,
    required this.label,
    required this.dataSource,
    this.labelKey = 'label',
    this.valueKey = 'value',
    this.initialValue,
    this.onChanged,
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
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ColorSchema.primaryColor, width: 1),
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
                      onTap: () => handleSelect(actualValue),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorSchema.primaryColor
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
                                  : ColorSchema.primaryColor,
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
      ],
    );
  }
}
