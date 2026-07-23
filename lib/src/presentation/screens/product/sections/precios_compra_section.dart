import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/utils/formats.dart';

class PreciosCompraSection extends HookConsumerWidget {
  const PreciosCompraSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El precio de compra es dato sensible: solo visible con permiso
    if (!ref.watch(sesionProvider).hasPermission('PRODUCTOS_MOSTRAR_PRECIO_COMPRA')) {
      return const SizedBox.shrink();
    }
    final formProvider = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);
    
    final precioCompraTemporalController = useTextEditingController(
        text: formatDouble(formProvider.precioCompraTemporal));
    final precioCompraNetoController = useTextEditingController(
        text: formatDouble(formProvider.precioCompraTemporal));
    
    final bool unidadesDiferentes = formProvider.unidad.descripcion !=
        formProvider.unidadCompra.descripcion;

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        precioCompraNetoController.text =
            formatDouble(formProvider.precioCompraNeto);
      });
      return null;
    }, [formProvider.precioCompraNeto]);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Center(
                    child: Title(
                        color: Colors.black,
                        child: Text(
                          "Precios de compra X ${formProvider.unidadCompra.descripcion}",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFieldSection(
                        label:
                            "Bruto x ${formProvider.unidadCompra.descripcion}",
                        controller: precioCompraTemporalController,
                        hint: "Precio Compra",
                        inputType: TextInputType.number,
                        showDoneButton: true,
                        onChanged: (value) => value.isNotEmpty
                            ? notifier.setPrecioCompraTemporal(
                                double.parse(value))
                            : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFieldSection(
                        label:
                            "Neto x ${formProvider.unidadCompra.descripcion}",
                        controller: precioCompraNetoController,
                        hint: "Precio Compra Neto",
                        inputType: TextInputType.number,
                        isReadOnly: true,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            notifier.setPrecioCompraTemporal(
                                double.parse(value));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (unidadesDiferentes) const SizedBox(height: 10),
        if (unidadesDiferentes)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black12),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Center(
                      child: Title(
                          color: Colors.black,
                          child: Text(
                            "Precios de compra x ${formProvider.unidad.descripcion}",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ))),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Precio Bruto",
                            ),
                            SizedBox(height: 2),
                            Text(
                              formatDouble(
                                  formProvider.precioCompraPorPieza),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Precio Neto",
                            ),
                            SizedBox(height: 2),
                            Text(
                              formatDouble(
                                  formProvider.precioCompraNetoPorPieza),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}