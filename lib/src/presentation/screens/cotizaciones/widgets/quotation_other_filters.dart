import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/quotation/quotation_list_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class QuotationOtherFilters extends ConsumerStatefulWidget {
  final VoidCallback? onApplyFilters;

  const QuotationOtherFilters({super.key, this.onApplyFilters});

  @override
  ConsumerState<QuotationOtherFilters> createState() => _QuotationOtherFiltersState();
}

class _QuotationOtherFiltersState extends ConsumerState<QuotationOtherFilters> {
  final TextEditingController _serieController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();

  String _selectedEstado = 'Todos';

  final List<String> _estadoOptions = ['Todos', 'PENDIENTE', 'ANULADA', 'CONCRETADA'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFiltersFromProvider());
  }

  @override
  void dispose() {
    _serieController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  void _loadFiltersFromProvider() {
    final currentState = ref.read(quotationListProvider);
    _serieController.text = currentState.filtroSerie ?? '';
    _numeroController.text = currentState.filtroNumero ?? '';
    setState(() {
      _selectedEstado = currentState.filtroEstadoCotizacion ?? 'Todos';
    });
  }

  void _applyFilters() {
    ref.read(quotationListProvider.notifier).updateFilters(
          serie: _serieController.text.trim(),
          numero: _numeroController.text.trim(),
          estadoCotizacion: _selectedEstado,
        );
    widget.onApplyFilters?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFieldSection(
                  label: 'Serie',
                  hint: 'Ej. C001',
                  inputType: TextInputType.text,
                  controller: _serieController,
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFieldSection(
                  label: 'Número',
                  hint: 'Ej. 000123',
                  inputType: TextInputType.number,
                  controller: _numeroController,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownFormFieldSection(
            label: 'Estado',
            hint: 'Selecciona un estado',
            selectionItem: _selectedEstado,
            items: _estadoOptions,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedEstado = value);
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Volver',
                    style: GoogleFonts.roboto(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorSchema.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Aplicar',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
