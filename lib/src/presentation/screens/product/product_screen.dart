import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teki_app/src/data/models/currency.dart';
import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/data/models/unitCode.dart';
import 'package:teki_app/src/presentation/screens/product/sections/list_precio_venta.dart';
import 'package:teki_app/src/presentation/screens/product/sections/product_not_found_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/floating_aciton_button/custom_floating_action_button.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/presentation/widgets/switch/custom_switch.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';
import 'package:teki_app/src/providers/formularios/product_form.dart';
import 'package:teki_app/src/providers/products/product.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductScreen extends ConsumerStatefulWidget {
  final int? productId;
  const ProductScreen({super.key, this.productId});

  @override
  ConsumerState<ProductScreen> createState() => _AddProductMainScreenState();
}

class _AddProductMainScreenState extends ConsumerState<ProductScreen>
    with TickerProviderStateMixin {
  String categorySelectedValue = '';
  String brandSelectedValue = '';
  String unitSelectedValue = '';
  String taxSelectedValue = '';
  String taxMethodSelectedValue = '';
  String warehouseSelectedValue = "";

  List<String> categoryItems = ["Computer", "Television", "Shoes", "Fruits"];
  List<String> brandItems = ["Dell", "Acer", "Asus", "Hp", "Lenovo"];
  List<String> taxItems = ["12%", "11%", "10%", "9%", "8%"];
  List<String> taxMethodItems = ["Exclusive", "Non - Exclusive"];
  List<String> unitItems = ["Kilogram", "Meter", "Piece"];
  List<String> warehouseItems = ["Warehouse 1", "Warehouse 2", "Warehouse 3"];
  List<String> productTypeItems = [
    "ARTICULO",
    "PLATILLO",
    "INSUMO",
    "PLAN",
    "PAQUETE_PRODUCIDO",
    "PLATILLO_PRODUCIDO",
  ];
  List<String> productTypeLote = [
    "Lote",
    "Serie",
  ];

  String img = "assets/images/products/apple_device.png";
  bool _loaded = false;
  late TabController tabController;
  final factorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController =
        TabController(length: 2, vsync: this); // aquí está el cambio
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      Future.microtask(() async {
        await ref.read(productProvider.notifier).loadMainData();

        List<Currency> currencies = ref.read(productProvider).currencies!;
        List<UnitCode> unitCodes = ref.read(productProvider).unitCodes!;
        if (widget.productId != null) {
          await ref
              .read(productProvider.notifier)
              .loadProduct(widget.productId!);
        }
        Product product = ref.read(productProvider).product!;
        ref
            .read(productFormProvider.notifier)
            .loadDataFromProduct(product, currencies, unitCodes);
      });
      _loaded = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    factorController.dispose();
    tabController.dispose();
    _loaded = false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(productProvider);
    final formProvider = ref.watch(productFormProvider);

    ref.listen(
      productFormProvider,
      (prev, next) {
        final formatted = formatDouble(next.factor);
        if (prev?.factor.toString() != next.factor.toString()) {
          factorController.text = formatted;
        }
      },
    );

    return provider.isLoading!
        ? ScreenLoader(message: 'Cargando Producto...')
        : Scaffold(
            appBar: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: CustomAppBar(
                  navigateName: widget.productId == null
                      ? "Crear Producto"
                      : "Editar Producto",
                )),
            body: provider.isError!
                ? ProductNotFoundScreen()
                : Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                            labelColor: ColorSchema.primaryColor,
                            indicatorColor: ColorSchema.primaryColor,
                            labelStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                            controller: tabController,
                            tabs: const [
                              Tab(text: "General"),
                              Tab(text: "Precios"),
                            ]),
                      ),
                      Expanded(
                        child: TabBarView(controller: tabController, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            color: Colors.white54,
                            child: ListView(
                              children: [
                                const SizedBox(
                                  height: 40,
                                ),
                                UploadImage(
                                  image: formProvider.imagenUrl,
                                  onImageSelected: (newImage, file) {
                                    ref
                                        .read(productFormProvider.notifier)
                                        .setImagenUrl(newImage);
                                    if (file != null) {
                                      ref
                                          .read(productFormProvider.notifier)
                                          .setImagenFile(file);
                                    }
                                  },
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextFieldSection(
                                    label: "Producto",
                                    initialValue: formProvider.nombre,
                                    hint: "Nombre del Producto",
                                    inputType: TextInputType.name,
                                    onChanged: ref
                                        .read(productFormProvider.notifier)
                                        .setNombre),
                                const SizedBox(
                                  height: 20,
                                ),
                                DropdownFormFieldSection(
                                    label: "Tipo de Producto",
                                    hint: "Selecciona una unidad de producto",
                                    items: productTypeItems,
                                    selectionItem: formProvider.tipoProducto,
                                    onChanged: (value) => ref
                                        .read(productFormProvider.notifier)
                                        .setTipoProducto(value!)),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: DropdownFormFieldSection(
                                          label: "Unidad compra",
                                          hint:
                                              "Selecciona una unidad de compra",
                                          items: formProvider.unidades
                                              .map((e) => e.descripcion ?? "")
                                              .toList(),
                                          selectionItem: formProvider
                                              .unidadCompra.descripcion,
                                          onChanged: (value) => ref
                                              .read(
                                                  productFormProvider.notifier)
                                              .setUnidadCompra(value!)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownFormFieldSection(
                                          label: "Unidad Venta",
                                          hint:
                                              "Selecciona una unidad de venta",
                                          items: formProvider.unidades
                                              .map((e) => e.descripcion ?? "")
                                              .toList(),
                                          selectionItem:
                                              formProvider.unidad.descripcion,
                                          onChanged: (value) => ref
                                              .read(
                                                  productFormProvider.notifier)
                                              .setUnidad(value!)),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextFieldSection(
                                  label: "Factor",
                                  controller: factorController,
                                  hint: "Factor",
                                  isReadOnly: formProvider.unidad.descripcion ==
                                      formProvider.unidadCompra.descripcion,
                                  inputType: TextInputType.number,
                                  onChanged: (value) {
                                    ref
                                        .read(productFormProvider.notifier)
                                        .setFactor(double.parse(value));
                                  },
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: CustomSwitch(
                                        title: "IGV",
                                        value: formProvider.igv,
                                        onChanged: (value) {
                                          ref
                                              .read(
                                                  productFormProvider.notifier)
                                              .setIgv(value);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CustomSwitch(
                                        title: "Usar lote",
                                        value: formProvider.validacionLote,
                                        onChanged: (value) {
                                          ref
                                              .read(
                                                  productFormProvider.notifier)
                                              .setValidacionLote(value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
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
                                        onChanged: (value) => ref
                                            .read(productFormProvider.notifier)
                                            .setMoneda(value!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IntrinsicWidth(
                                      child: CustomSegmentedSelector(
                                        label: "Tipo de Producto",
                                        options: productTypeLote,
                                        selected: formProvider.tipoLote,
                                        onChanged: (value) {
                                          ref
                                              .read(
                                                  productFormProvider.notifier)
                                              .setTipoLote(value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 6,
                                      child: TextFieldSection(
                                          label: "Product Code",
                                          hint: "Enter Product Code",
                                          inputType: TextInputType.number),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFFCFCFC),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFFE2E4E7),
                                                    width: 1)),
                                            child: SvgPicture.asset(
                                              "assets/icons/icon_svg/barcode.svg",
                                              width: 55,
                                            )))
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                DropdownFormFieldSection(
                                    label: "Product Tax",
                                    hint: "Select Product Tax",
                                    items: taxItems,
                                    selectionItem: taxSelectedValue),
                                const SizedBox(
                                  height: 20,
                                ),
                                DropdownFormFieldSection(
                                  label: "Tax Method",
                                  hint: "Select Tax Method",
                                  items: taxMethodItems,
                                  selectionItem: taxMethodSelectedValue,
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Row(
                                  children: [
                                    Expanded(
                                      child: TextFieldSection(
                                          label: "Product Price",
                                          hint: "Enter Product Price",
                                          inputType: TextInputType.number),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: TextFieldSection(
                                          label: "Product Stock",
                                          hint: "Enter Product Stock",
                                          inputType: TextInputType.number),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 80,
                                ),
                              ],
                            ),
                          ),
                          ListPrecioVenta(),
                        ]),
                      )
                    ],
                  ),
            floatingActionButton: provider.isError!
                ? null
                : CustomFloatingActionButton(
                    iconData:
                        widget.productId != null ? Icons.edit : Icons.save,
                  ),
          );
  }
}
