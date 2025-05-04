import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/productPrice.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ListPrecioVenta extends ConsumerStatefulWidget {
  const ListPrecioVenta({super.key});
  @override
  ConsumerState<ListPrecioVenta> createState() => _ListPrecioVentaState();
}

class _ListPrecioVentaState extends ConsumerState<ListPrecioVenta> {
  @override
  Widget build(BuildContext context) {
    final preciosVenta = ref.watch(productFormProvider).preciosVenta;

    return Container(
      color: Colors.white54,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      color: ColorSchema.primaryColor),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      size: 20, color: ColorSchema.primaryColor),
                  onPressed: () {
                    ref.read(productFormProvider.notifier).addNewPrice();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: preciosVenta.length,
              itemBuilder: (context, index) {
                final item = preciosVenta[index];
                return GestureDetector(
                  onTap: () {
                    buildModalBottomSheet(context, index, ref);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(item.nombre ?? 'Sin nombre'),
                      subtitle: Text('Precio: ${item.precio}'),
                      trailing: index > 0
                          ? GestureDetector(
                              onTap: () {
                                ref
                                    .read(productFormProvider.notifier)
                                    .removePrice(index);
                              },
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: ColorSchema.primaryColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void buildModalBottomSheet(BuildContext context, int index, WidgetRef ref) {
  final precioVenta = ref.read(productFormProvider).preciosVenta[index];

  final nombreController =
      TextEditingController(text: precioVenta.nombre ?? "");

  final tiposPrecioVenta = const [
    {"label": "Por Defecto", "value": "POR_DEFECTO"},
    {"label": "Mayoreo", "value": "MAYOREO"},
    {"label": "Especial", "value": "ESPECIAL"},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12), topRight: Radius.circular(12)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateModal) {
          return Consumer(builder: (context, ref, _) {
            final precioActualizado =
                ref.watch(productFormProvider).preciosVenta[index];
            // actualiza el valor del TextField si cambia desde el provider
            nombreController.text = precioActualizado.nombre ?? "";
            final double height = MediaQuery.of(context).size.height * 0.75;
            final bool isReadOnly =
                precioActualizado.tipoPrecio == "POR_DEFECTO";
            return Container(
              constraints: BoxConstraints(
                maxHeight: height,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Editar precio de venta',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 15,
                      runSpacing: 20,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 30,
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
                                });
                              }),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 30,
                          child: TextFieldSection(
                            label: "% Utilidad",
                            hint: "Utilidad",
                            inputType: TextInputType.name,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 30,
                          child: TextFieldSection(
                            label: "Precio Venta Neto",
                            hint: "",
                            inputType: TextInputType.number,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 30,
                          child: TextFieldSection(
                            label: "Precioi Venta",
                            hint: "",
                            inputType: TextInputType.name,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                          child: TextFieldSection(
                            label: "Unidades mayoreo",
                            hint: "Nombre del Producto",
                            inputType: TextInputType.name,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                          child: DropdownFormFieldSection(
                            label: "Tipo de Precio",
                            hint: "Selecciona el tipo de precio",
                            itemsMap: tiposPrecioVenta,
                            labelKey: "label",
                            valueKey: "value",
                            selectionItem: precioVenta.tipoPrecio,
                            onChanged: (value) {
                              ref
                                  .read(productFormProvider.notifier)
                                  .modifyPrecioVenta(index, (item) {
                                return item.copyWith(
                                  tipoPrecio: value);
                              });
                              setStateModal(() {});
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
        },
      );
    },
  );
}
