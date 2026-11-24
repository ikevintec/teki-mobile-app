import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/customers/customers.dart';
import 'package:teki_app/src/utils/constants.dart';

class CustomerFiltersModal extends ConsumerStatefulWidget {
  final VoidCallback? onApplyFilters;
  
  const CustomerFiltersModal({
    super.key,
    this.onApplyFilters,
  });

  @override
  ConsumerState<CustomerFiltersModal> createState() => _CustomerFiltersModalState();
}

class _CustomerFiltersModalState extends ConsumerState<CustomerFiltersModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiltersFromProvider();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadFiltersFromProvider() {
    final currentState = ref.read(customersProvider);
    
    _nameController.text = currentState.filtro ?? '';
    _phoneController.text = currentState.telefono ?? '';
    _emailController.text = currentState.email ?? '';
  }

  void _applyFilters() {
    ref.read(customersProvider.notifier).setFiltro(_nameController.text.trim());
    ref.read(customersProvider.notifier).setTelefono(_phoneController.text.trim());
    ref.read(customersProvider.notifier).setEmail(_emailController.text.trim());
    ref.read(customersProvider.notifier).loadFirstPage();
    widget.onApplyFilters?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros de Clientes',
                style: GoogleFonts.raleway(
                  color: const Color(0xFF444444),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          TextFieldSection(
            label: 'Nombre del Cliente',
            hint: 'Ingrese nombre o razón social',
            inputType: TextInputType.text,
            controller: _nameController,
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFieldSection(
                  label: 'Teléfono',
                  hint: 'Número de teléfono',
                  inputType: TextInputType.phone,
                  controller: _phoneController,
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFieldSection(
                  label: 'Email',
                  hint: 'Correo electrónico',
                  inputType: TextInputType.emailAddress,
                  controller: _emailController,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
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
                  onPressed: () {
                    _applyFilters();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorSchema.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
          const SizedBox(height: 20),
        
        ],
      ),
    );
  }
}