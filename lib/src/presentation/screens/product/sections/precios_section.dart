import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/presentation/screens/product/sections/precios_compra_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductPreciosSection extends HookConsumerWidget {
  final GlobalKey<FormState> formKey;

  const ProductPreciosSection({super.key, required this.formKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preciosVenta = ref.watch(productFormProvider).preciosVenta;
    final tiposPrecioVenta = const [
      {"label": "Por Defecto", "value": "POR_DEFECTO"},
      {"label": "Mayoreo", "value": "MAYOREO"},
      {"label": "Especial", "value": "ESPECIAL"},
    ];

    final scrollController = useScrollController();
    final prevLength = useRef(preciosVenta.length);

    useEffect(() {
      if (preciosVenta.length > prevLength.value) {
        Future.delayed(const Duration(milliseconds: 300), () {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
      prevLength.value = preciosVenta.length;
      return null;
    }, [preciosVenta.length]);

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 25),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PreciosCompraSection(),
                Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        size: 16, color: ColorSchema.primaryColor),
                    const SizedBox(width: 6),
                    const Text(
                      'Precios de Venta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          size: 20, color: ColorSchema.primaryColor),
                      onPressed: () =>
                          ref.read(productFormProvider.notifier).addNewPrice(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...preciosVenta.asMap().entries.map((entry) {
                  final index = entry.key;
                  return Column(
                    children: [
                      if (index != 0) const SizedBox(height: 40),
                      PriceEditBottomSheet(
                        index: index,
                        tiposPrecioVenta: tiposPrecioVenta,
                        formKey: formKey,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      );
  }
}

class PriceEditBottomSheet extends HookConsumerWidget {
  final int index;
  final List<Map<String, String>> tiposPrecioVenta;
  final GlobalKey<FormState> formKey;

  const PriceEditBottomSheet({
    super.key,
    required this.index,
    required this.tiposPrecioVenta,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Map<String, String>> tiposPrecioVentaFiltrado =
        tiposPrecioVenta.sublist(index == 0 ? 0 : 1);

    final precioVenta = ref.watch(productFormProvider).preciosVenta[index];
    final nombreController =
        useTextEditingController(text: precioVenta.nombre ?? "");
    final utilidadController = useTextEditingController(
        text: precioVenta.margenUtilidad != null
            ? '${formatDouble(precioVenta.margenUtilidad!)}%'
            : "");
    final precioController = useTextEditingController(
        text: precioVenta.precio != null
            ? formatDouble(precioVenta.precio!)
            : "");
    final unidadesMayoreoController = useTextEditingController(
        text: precioVenta.unidadesMayoreo != null
            ? formatDouble(precioVenta.unidadesMayoreo!)
            : "");

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nombreController.text = precioVenta.nombre ?? "";
      });
      return null;
    }, [precioVenta.nombre]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        utilidadController.text =
            '${formatDouble(precioVenta.margenUtilidad ?? 0)}%';
      });
      return null;
    }, [precioVenta.margenUtilidad]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unidadesMayoreoController.text =
            formatDouble(precioVenta.unidadesMayoreo ?? 0);
      });
      return null;
    }, [precioVenta.unidadesMayoreo]);

    final bool isReadOnly = precioVenta.tipoPrecio != "ESPECIAL";
    final bool isMayoreo = precioVenta.tipoPrecio != "POR_DEFECTO";

    return Stack(
      children: [
        Container(
          padding: index != 0 ? const EdgeInsets.only(top: 40, bottom: 20, left: 15, right: 15) : const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double halfWidth = (constraints.maxWidth - 15) / 2;
              return Wrap(
                spacing: 15,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: halfWidth,
                    child: TextFieldSection(
                      label: "Nombre",
                      hint: "Nombre del precio",
                      inputType: TextInputType.name,
                      controller: nombreController,
                      isReadOnly: isReadOnly,
                      onChanged: (value) {
                        ref
                            .read(productFormProvider.notifier)
                            .modifyPrecioVenta(index, (item) {
                          return item.copyWith(nombre: value);
                        }, false);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Campo requerido";
                        if (value == "-") return "Nombre invalido";
                        if (value.length < 3) return "Nombre muy corto";
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: halfWidth,
                    child: TextFieldSection(
                      label: "Precio Venta",
                      hint: "",
                      controller: precioController,
                      inputType: TextInputType.number,
                      showDoneButton: true,
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        ref
                            .read(productFormProvider.notifier)
                            .modifyPrecioVenta(index, (item) {
                          return item.copyWith(precio: double.parse(value));
                        }, false);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Campo requerido";
                        }
                        if (double.tryParse(value) == null) {
                          return "El precio no es válido";
                        }
                        if (double.parse(value) <= 0) {
                          return "Precio no debe ser 0";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: halfWidth,
                    child: TextFieldSection(
                      controller: utilidadController,
                      label: "Utilidad",
                      hint: "Utilidad",
                      isReadOnly: true,
                      inputType: TextInputType.name,
                    ),
                  ),
                  SizedBox(
                    width: halfWidth,
                    child: TextFieldSection(
                      label: "Precio Venta Neto",
                      hint: "",
                      isReadOnly: true,
                      inputType: TextInputType.number,
                    ),
                  ),
                  if (isMayoreo)
                    SizedBox(
                      width: constraints.maxWidth,
                      child: TextFieldSection(
                        label: "Unidades mayoreo",
                        hint: "Unidades al mayoreo",
                        controller: unidadesMayoreoController,
                        inputType: TextInputType.number,
                        showDoneButton: true,
                        onChanged: (value) {
                          ref
                              .read(productFormProvider.notifier)
                              .modifyPrecioVenta(index, (item) {
                            return item.copyWith(
                                unidadesMayoreo: double.parse(value));
                          }, false);
                        },
                        validator: (value) {
                          if (precioVenta.tipoPrecio == "POR_DEFECTO")
                            return null;
                          if (value == null || value.isEmpty) {
                            return "Campo requerido";
                          }
                          if (double.tryParse(value) == null) {
                            return "El precio no es válido";
                          }
                          if (double.parse(value) <= 0) {
                            return "Unidad minima es 1";
                          }
                          return null;
                        },
                      ),
                    ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: DropdownFormFieldSection(
                      label: "Tipo de Precio",
                      hint: "Selecciona el tipo de precio",
                      itemsMap: tiposPrecioVentaFiltrado,
                      labelKey: "label",
                      valueKey: "value",
                      readOnly: index == 0 ? true : false,
                      selectionItem: precioVenta.tipoPrecio,
                      onChanged: (value) {
                        ref
                            .read(productFormProvider.notifier)
                            .modifyPrecioVenta(index, (item) {
                          return item.copyWith(tipoPrecio: value);
                        }, true);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (index != 0)
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close,
                size: 20, color: Colors.red),
            onPressed: () {
              ref.read(productFormProvider.notifier).removePrice(index);
            },
          ),
        ),
      ],
    );
  }
}
