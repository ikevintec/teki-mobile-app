import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/utils/constants.dart';

// ─── Tab "Crédito": días de crédito + cuotas ─────────────────────────────────

class CreditoTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController diasCredito;
  final List<TextEditingController> fechaCredito;
  final List<TextEditingController> montoCredito;
  final VoidCallback onAddCuota;
  final void Function(int index) onRemoveCuota;
  final void Function(int index) onSelectDate;

  const CreditoTab({
    super.key,
    required this.formKey,
    required this.diasCredito,
    required this.fechaCredito,
    required this.montoCredito,
    required this.onAddCuota,
    required this.onRemoveCuota,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextFieldSection(
                      label: 'Días de crédito (*)',
                      hint: 'Ingrese días',
                      inputType: TextInputType.text,
                      controller: diasCredito,
                      onChanged: (_) {},
                      validator: (p0) => (p0 == null || p0.isEmpty)
                          ? 'Ingrese un número válido'
                          : (int.tryParse(p0) == null ||
                                  int.parse(p0) <= 0)
                              ? 'Debe ser mayor a cero'
                              : null,
                    ),
                  ),
                  IconButton(
                    onPressed: onAddCuota,
                    icon: const Icon(Icons.add_circle,
                        color: ColorSchema.primaryColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Cuotas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
            ),
            ...List.generate(fechaCredito.length, (index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => onSelectDate(index),
                        child: AbsorbPointer(
                          child: TextFieldSection(
                            label: 'Fecha',
                            hint: 'Seleccione fecha',
                            inputType: TextInputType.text,
                            controller: fechaCredito[index],
                            isReadOnly: true,
                            onChanged: (_) {},
                            validator: (p0) =>
                                (p0 == null || p0.isEmpty)
                                    ? 'Seleccione una fecha'
                                    : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFieldSection(
                        label: 'Monto cuota',
                        hint: 'Monto',
                        controller: montoCredito[index],
                        inputType: TextInputType.number,
                        validator: (p0) =>
                            (p0 == null || p0.isEmpty)
                                ? 'Monto requerido'
                                : (double.tryParse(p0) == null ||
                                        double.parse(p0) <= 0)
                                    ? 'Monto invalido'
                                    : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle,
                          color: Colors.red),
                      onPressed: () => onRemoveCuota(index),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
