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
    final precioCompraTemporalController = useTextEditingController(
        text: formatDouble(formProvider.precioCompraTemporal));
    final precioCompraNetoController = useTextEditingController(
        text: formatDouble(formProvider.precioCompraTemporal));
    final bool unidadesDiferentes = formProvider.unidad.descripcion !=
        formProvider.unidadCompra.descripcion;
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        factorController.text = formatDouble(formProvider.factor);
      });
      return null;
    }, [formProvider.unidad, formProvider.unidadCompra]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        precioCompraNetoController.text =
            formatDouble(formProvider.precioCompraNeto);
      });
      return null;
    }, [formProvider.precioCompraNeto]);

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
                if (file != null) {
                  notifier.setImagenFile(file);
                }
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
                const SizedBox(width: 8),
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
                            onChanged: (value) => value.isNotEmpty
                                ? notifier.setPrecioCompraTemporal(
                                    double.parse(value))
                                : null,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Campo requerido";
                              }
                              if (double.parse(value) <= 0) {
                                return "Precio minimo es 1";
                              }
                              if (double.parse(value) > 99999999) {
                                return "Precio fuera de limite";
                              }
                              return null;
                            },
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
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
