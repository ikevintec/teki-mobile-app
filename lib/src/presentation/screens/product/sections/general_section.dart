import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/presentation/widgets/switch/custom_switch.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/pick_product_image.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/utils/contstants.dart';
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
            const SizedBox(height: 30),
            UploadImage(
              image: formProvider.imagenSeleccionada?.url ?? '',
              onImageSelected: (newImage, file) {
                notifier.setImagenSeleccionadaFile(newImage, file);
              },
            ),
            const SizedBox(height: 16),
            _ProductImageStrip(
              imagenes: formProvider.imagenes,
              selectedSlot: formProvider.imagenSeleccionadaSlot,
              onAdd: () async {
                final file = await pickProductImage(context);
                if (file == null) return;
                notifier.addImagen(file.path, file);
              },
              onReorder: notifier.reordenarImagenes,
              onSelect: notifier.setImagenSeleccionada,
              onRemove: notifier.removeImagen,
              onSetDefault: notifier.setImagenPorDefecto,
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

/// Tira horizontal de miniaturas bajo el círculo. Las imágenes se muestran
/// siempre en orden y contiguas, seguidas de un botón "+" (hasta
/// [ProductFormNotifier.maxImagenes]). Interacciones:
/// - Tap: selecciona la imagen (se muestra en el círculo).
/// - Tap sobre la ya seleccionada: abre menú "Hacer principal" / "Eliminar".
/// - Mantener presionado y arrastrar: cambia la posición (reordena).
class _ProductImageStrip extends StatelessWidget {
  final List<ProductImageDraft> imagenes;
  final int selectedSlot;
  final VoidCallback onAdd;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int numeroOrden) onSelect;
  final void Function(int numeroOrden) onRemove;
  final void Function(int numeroOrden) onSetDefault;

  const _ProductImageStrip({
    required this.imagenes,
    required this.selectedSlot,
    required this.onAdd,
    required this.onReorder,
    required this.onSelect,
    required this.onRemove,
    required this.onSetDefault,
  });

  void _mostrarOpciones(BuildContext context, ProductImageDraft draft) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (!draft.porDefecto)
              ListTile(
                leading: const Icon(Icons.star, color: ColorSchema.primaryColor),
                title: const Text('Hacer principal'),
                onTap: () {
                  Navigator.pop(ctx);
                  onSetDefault(draft.numeroOrden);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar'),
              onTap: () {
                Navigator.pop(ctx);
                onRemove(draft.numeroOrden);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = imagenes.length < ProductFormNotifier.maxImagenes;
    final itemCount = imagenes.length + (canAdd ? 1 : 0);
    return SizedBox(
      height: 70,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.symmetric(vertical: 3),
        itemCount: itemCount,
        onReorder: (oldIndex, newIndex) {
          // El botón "+" no se reordena.
          if (oldIndex >= imagenes.length) return;
          if (newIndex > imagenes.length) newIndex = imagenes.length;
          onReorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          // Último ítem: botón para agregar (no arrastrable).
          if (index >= imagenes.length) {
            return Padding(
              key: const ValueKey('add-tile'),
              padding: const EdgeInsets.only(right: 10),
              child: _AddTile(onTap: onAdd),
            );
          }
          final draft = imagenes[index];
          return Padding(
            key: ValueKey('img-${draft.url}'),
            padding: const EdgeInsets.only(right: 10),
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: _Thumbnail(
                draft: draft,
                isSelected: draft.numeroOrden == selectedSlot,
                onTap: () {
                  if (draft.numeroOrden == selectedSlot) {
                    _mostrarOpciones(context, draft);
                  } else {
                    onSelect(draft.numeroOrden);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.add_a_photo_outlined,
            color: Colors.grey, size: 22),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final ProductImageDraft draft;
  final bool isSelected;
  final VoidCallback onTap;

  const _Thumbnail({
    required this.draft,
    required this.isSelected,
    required this.onTap,
  });

  Widget _image() {
    final url = draft.url;
    if (url.isEmpty) {
      return Container(color: const Color(0xFFF5F5F5));
    }
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)));
      });
    }
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover);
    }
    return Image.file(File(url), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? ColorSchema.primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _image(),
                  // Seleccionada: velo oscuro + badge de tres puntos en color
                  // primario. Indica que al tocarla de nuevo hay más opciones.
                  if (isSelected) ...[
                    Container(color: Colors.black.withValues(alpha: 0.4)),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: ColorSchema.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                  // Imagen principal: franja amarilla inferior con estrella
                  // blanca. Imposible que no se distinga.
                  if (draft.porDefecto)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: ColorSchema.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Índice de orden (izquierda = 1). Minimalista.
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${draft.numeroOrden + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
