import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/presentation/widgets/switch/custom_switch.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductGeneralSection extends HookConsumerWidget {
  final GlobalKey<FormState> formKey;

  const ProductGeneralSection({super.key, required this.formKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formProvider = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);
    final factorController =
        useTextEditingController(text: formatDouble(formProvider.factor));
    final nombreController =
        useTextEditingController(text: formProvider.nombre);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        factorController.text = formatDouble(formProvider.factor);
      });
      return null;
    }, [formProvider.unidad, formProvider.unidadCompra]);


    List<String> productTypeItems = [
      "ARTICULO",
      "PLATILLO",
      "INSUMO",
      "PLAN",
      "PAQUETE_PRODUCIDO",
      "PLATILLO_PRODUCIDO",
    ];
    List<String> productTypeLote = ["Lote", "Serie"];

    return Form(
      key: formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        color: Colors.white54,
        child: ListView(
          children: [
            const SizedBox(height: 40),
            UploadImage(
              image: formProvider.imagenUrl,
              onImageSelected: (newImage, file) {
                notifier.setImagenUrl(newImage);
                notifier.setImagenFile(file);
              },
            ),
            const SizedBox(height: 20),
            TextFieldSection(
              label: "Producto",
              controller: nombreController,
              hint: "Nombre del Producto",
              inputType: TextInputType.name,
              onChanged: notifier.setNombre,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Campo requerido";
                }
                if (value.length < 3) {
                  return "El nombre debe tener al menos 3 caracteres";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownFormFieldSection(
                    label: "Tipo de Producto",
                    hint: "Selecciona una unidad de producto",
                    items: productTypeItems,
                    selectionItem: formProvider.tipoProducto,
                    onChanged: (value) => notifier.setTipoProducto(value!),
                  ),
                ),

                if(formProvider.validacionLote)
                const SizedBox(width: 8),
                if(formProvider.validacionLote)
                IntrinsicWidth(
                  child: CustomSegmentedSelector(
                    label: "Tipo de Producto",
                    options: productTypeLote,
                    selected: formProvider.tipoLote,
                    onChanged: notifier.setTipoLote,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownFormFieldSection(
                    label: "Moneda",
                    hint: "Seleccione la moneda",
                    items: formProvider.currencies
                        .map((e) => e.codigoMoneda ?? "")
                        .toList(),
                    selectionItem: formProvider.moneda,
                    onChanged: (value) => notifier.setMoneda(value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomSwitch(
                    title: "Usa lote",
                    value: formProvider.validacionLote,
                    onChanged: notifier.setValidacionLote,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownFormFieldSection(
                    label: "Unidad compra",
                    hint: "Selecciona una unidad de compra",
                    items: formProvider.unidades
                        .map((e) => e.descripcion ?? "")
                        .toList(),
                    selectionItem: formProvider.unidadCompra.descripcion,
                    onChanged: (value) => notifier.setUnidadCompra(value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownFormFieldSection(
                    label: "Unidad Venta",
                    hint: "Selecciona una unidad de venta",
                    items: formProvider.unidades
                        .map((e) => e.descripcion ?? "")
                        .toList(),
                    selectionItem: formProvider.unidad.descripcion,
                    onChanged: (value) => notifier.setUnidad(value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFieldSection(
                    label: "Factor",
                    controller: factorController,
                    hint: "Factor",
                    isReadOnly: formProvider.unidad.descripcion ==
                        formProvider.unidadCompra.descripcion,
                    inputType: TextInputType.number,
                    showDoneButton: true,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        notifier.setFactor(double.parse(value));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomSwitch(
                    title: "IGV",
                    value: formProvider.igv,
                    onChanged: notifier.setIgv,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (formProvider.igv == true)
              CustomSwitch(
                title: "Aplicar impuestos",
                value: formProvider.precioCompraIncImp,
                onChanged: notifier.setPrecioCompraIncImp,
              ),
            if (formProvider.igv == true) const SizedBox(height: 20),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
