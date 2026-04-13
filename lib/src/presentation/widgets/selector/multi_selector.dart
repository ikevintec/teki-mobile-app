import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class MultiSelector extends StatefulWidget {
  final String label;
  final String hint;
  final List<Map<String, String>> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>>? onChanged;
  final String labelKey;
  final String valueKey;
  final bool enabled;

  const MultiSelector({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.selectedValues,
    this.onChanged,
    this.labelKey = 'label',
    this.valueKey = 'value',
    this.enabled = true,
  });

  @override
  State<MultiSelector> createState() => _MultiSelectorState();
}

class _MultiSelectorState extends State<MultiSelector> {
  late List<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(MultiSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValues != oldWidget.selectedValues) {
      _selectedValues = List.from(widget.selectedValues);
    }
  }


  void _showSelectionModal() {
    if (!widget.enabled) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MultiSelectorModal(
        label: widget.label,
        options: widget.options,
        selectedValues: _selectedValues,
        labelKey: widget.labelKey,
        valueKey: widget.valueKey,
        onSelectionChanged: (values) {
          // Solo actualizar el estado local sin emitir el cambio
          setState(() {
            _selectedValues = values;
          });
        },
        onApplyPressed: () {
          // Emitir el cambio solo cuando se presione "Aplicar"
          widget.onChanged?.call(_selectedValues);
        },
      ),
    );
  }

  String _getDisplayText() {
    if (_selectedValues.isEmpty) return widget.hint;
    if (_selectedValues.length == 1) {
      final selectedOption = widget.options.firstWhere(
        (option) => option[widget.valueKey] == _selectedValues.first,
        orElse: () => {},
      );
      return selectedOption[widget.labelKey] ?? widget.hint;
    }
    return '${_selectedValues.length} seleccionados';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: _showSelectionModal,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E4E7)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getDisplayText(),
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _selectedValues.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: ColorSchema.primaryColor,
                ),
              ],
            ),
          ),
        ),
        // Label flotante
        Positioned(
          left: 12,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white,
            child: Text(
              widget.label,
              style: GoogleFonts.raleway(
                color: const Color(0xFF444444),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MultiSelectorModal extends StatefulWidget {
  final String label;
  final List<Map<String, String>> options;
  final List<String> selectedValues;
  final String labelKey;
  final String valueKey;
  final ValueChanged<List<String>> onSelectionChanged;
  final VoidCallback onApplyPressed;

  const _MultiSelectorModal({
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.labelKey,
    required this.valueKey,
    required this.onSelectionChanged,
    required this.onApplyPressed,
  });

  @override
  State<_MultiSelectorModal> createState() => _MultiSelectorModalState();
}

class _MultiSelectorModalState extends State<_MultiSelectorModal> {
  late List<String> _localSelectedValues;

  @override
  void initState() {
    super.initState();
    _localSelectedValues = List.from(widget.selectedValues);
  }

  void _toggleSelection(String value) {
    setState(() {
      if (_localSelectedValues.contains(value)) {
        _localSelectedValues.remove(value);
      } else {
        _localSelectedValues.add(value);
      }
    });
    // Solo actualizar la selección localmente, sin emitir el cambio
    widget.onSelectionChanged(_localSelectedValues);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  color: ColorSchema.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ColorSchema.primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final label = option[widget.labelKey] ?? '';
                final value = option[widget.valueKey] ?? '';
                final isSelected = _localSelectedValues.contains(value);
                
                return Card(
                  elevation: 0,
                  color: isSelected ? ColorSchema.primaryColor.withValues(alpha: 0.1) : Colors.grey[50],
                  child: ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? ColorSchema.primaryColor : Colors.grey[400],
                    ),
                    title: Text(
                      label,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? ColorSchema.primaryColor : Colors.black87,
                      ),
                    ),
                    onTap: () => _toggleSelection(value),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyPressed();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorSchema.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Aplicar Filtros',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}