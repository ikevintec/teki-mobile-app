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
            borderRadius: BorderRadius.circular(6),
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

                  return GestureDetector(
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
                              ? const Radius.circular(6)
                              : Radius.zero,
                          right: index == options.length - 1
                              ? const Radius.circular(6)
                              : Radius.zero,
                        ),
                      ),
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
