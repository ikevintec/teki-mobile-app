import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';
import 'package:teki_app/src/presentation/screens/sale/client/client_sale_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/product_item_card.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/search_products.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/modal_product_view.dart';
import 'package:teki_app/src/presentation/screens/sale/widgets/summary_bar.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/presentation/widgets/switch/custom_switch.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/widgets/dismissible_action_widget.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

class ProductsSaleScreen extends ConsumerStatefulWidget {
  final int? id;
  const ProductsSaleScreen({super.key,this.id});

  @override
  ConsumerState<ProductsSaleScreen> createState() => _ProductsSaleScreenState();
}

class _ProductsSaleScreenState extends ConsumerState<ProductsSaleScreen> {
  Timer? _debounce; // Timer para debounce
  late FocusNode _listFocusNode; // Focus node para toda la lista

  final ScrollController _scrollController = ScrollController();

  void _initializeFormArray() {
    final products = ref.read(productSaleProvider).productsSales;
    final formArray = form.control('products') as FormArray;
    formArray.clear();
    for (final product in products) {
      formArray.add(FormGroup({
        'description': FormControl<String>(
            value: "",
            validators: [Validators.required, Validators.minLength(3)]),
        'price': FormControl<double>(
            value: product.precioVentaUnitario ?? 0.0,
            validators: [Validators.required, Validators.min(1)]),
        'quantity': FormControl<int>(
            value: (product.cantidad ?? 1).toInt(),
            validators: [Validators.required, Validators.min(1)]),
      }));
    }
  }


  @override
  void initState() {
    super.initState();
    _listFocusNode = FocusNode();
    _initializeFormArray();
    // Listener para detectar cuando se pierde el focus de toda la lista
    _listFocusNode.addListener(() {
      if (!_listFocusNode.hasFocus) {
        _syncAllProductsToProvider();
      }
    });
    
    final providerProductSale = ref.read(productSaleProvider.notifier);
    Future.microtask(() {
      providerProductSale.loadInitialData(widget.id);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }
  
  void _syncAllProductsToProvider() {
    // Recopilar todos los datos de los formularios
    final formArray = form.control('products') as FormArray;
    final formsData = <Map<String, dynamic>>[];
    
    for (int i = 0; i < formArray.controls.length; i++) {
      final formGroup = formArray.controls[i] as FormGroup;
      formsData.add({
        'price': formGroup.control('price').value ?? 0.0,
        'description': formGroup.control('description').value ?? '',
        'quantity': formGroup.control('quantity').value ?? 1,
      });
    }
    
    // Llamar al método global del provider
    ref.read(productSaleProvider.notifier).syncAllProductsFromForms(formsData);
  }

  @override
  void dispose() {
    _listFocusNode.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  final form = FormGroup({
    'products': FormArray([
      FormGroup({
        'description': FormControl<String>(
            value: "",
            validators: [Validators.required, Validators.minLength(3)]),
        'price': FormControl<double>(
            value: 0.0, validators: [Validators.required, Validators.min(1)]),
        'quantity': FormControl<int>(
            value: 1, validators: [Validators.required, Validators.min(1)]),
      }),
    ], validators: [
      Validators.minLength(1),
    ]),
  });

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(productSaleProvider);
    final notifier = ref.read(productSaleProvider.notifier);
    final isLoading = provider.isLoading;
    final isBarcodeSearching = provider.isBarcodeSearching;
    final products = provider.productsSales;
    final ticketP = ref.watch(ticketProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFormArrayWithProvider(products, form, provider.incIgv, () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });
    });
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ticketP.ticket.pedidoRestaurante != null ? 72 : 60),
        child: CustomAppBar(
          navigateName: "Escoge los productos",
          subtitle: ticketP.ticket.pedidoRestaurante != null
              ? 'Pedido #${formatOrderNumber(ticketP.ticket.pedidoRestaurante!.id)}'
              : null,
        ),
      ),
      body: isLoading
          ? ScreenLoader(
              message: 'Cargando Información',
            )
          : ReactiveForm(
              formGroup: form,
              child: Container(
                color: ColorSchema.primaryColor,
                child: Column(
                  children: [
                    SearchProducts(
                      form: form,
                    ),
                    // add row with 2 buttons add product and add service
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, top: 15, right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Get.toNamed(AppRoutes.createProduct);
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Crear Producto',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                notifier.createItemForm();
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_note, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Producto Libre',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.only(
                          top: 20, bottom: 10, left: 20, right: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                                top: 3, bottom: 5, left: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: DropdownFormFieldSection(
                                    label: "",
                                    hint: "Elige una moneda",
                                    items: ref
                                        .watch(productSaleProvider)
                                        .currencies
                                        .map((c) => c.codigoMoneda!)
                                        .toList(),
                                    selectionItem: provider.currency?.codigoMoneda,
                                    onChanged: (value) {
                                      notifier.setCurrency(value!);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: CustomSwitch(
                                    title: "Inc. IGV",
                                    border: false,
                                    value: provider.incIgv,
                                    onChanged: notifier.setIncIgv,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: products.isEmpty
                            ? Center(
                                child:
                                    Text("Aun no hay productos seleccionados"),
                              )
                            : Focus(
                                focusNode: _listFocusNode,
                                child: ReactiveFormArray(
                                  formArray:
                                      form.control('products') as FormArray,
                                  builder: (context, formArray, child) {
                                  final controls = formArray.controls;
                                  final visibleItems =
                                      products.length < controls.length
                                          ? products.length
                                          : controls.length;
                                  return Stack(
                                    children: [
                                      ListView.builder(
                                        controller: _scrollController,
                                        itemCount: visibleItems,
                                        itemBuilder: (context, index) {
                                          final formGroup = formArray
                                              .controls[index] as FormGroup;
                                          return Column(
                                            children: [
                                              DismissibleActionWidget(
                                                actions: [
                                                  if (products[index].producto != null)
                                                    DismissibleActionData(
                                                      type: DismissibleActionType.edit,
                                                      label: 'Ver',
                                                      icon: Icons.visibility,
                                                      backgroundColor: ColorSchema.primaryColor,
                                                      onTap: () {
                                                        showCustomModal(
                                                          context: context,
                                                          child: ModalProductView(
                                                            product: products[index].producto!,
                                                            index: index,
                                                          ),
                                                          tittle: "Ver Producto",
                                                          allowButtons: false
                                                        );
                                                      },
                                                    ),
                                                  DismissibleActionData(
                                                    type: DismissibleActionType.edit,
                                                    label: 'Config',
                                                    icon: Icons.settings,
                                                    backgroundColor: ColorSchema.primaryColor.withValues(alpha: 0.8),
                                                    onTap: () {
                                                      // Aquí puedes agregar la lógica de configuración del producto
                                                      // Por ahora, solo muestra un mensaje
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Configuraciones del producto'),
                                                          backgroundColor: ColorSchema.primaryColor,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  if (products[index].comandaDetalle == null)
                                                    DismissibleActionData(
                                                      type: DismissibleActionType.edit,
                                                      label: 'Eliminar',
                                                      icon: Icons.delete,
                                                      backgroundColor: Colors.redAccent,
                                                      onTap: () {
                                                        Future.delayed(const Duration(milliseconds: 150), () {
                                                          ref
                                                              .read(productSaleProvider
                                                                  .notifier)
                                                              .removeProductSale(index);
                                                        });
                                                      },
                                                    ),
                                                ],
                                                child: ProductItemCard(
                                                  key: UniqueKey(),
                                                  productTicketDetail:
                                                      products[index],
                                                  index: index,
                                                  formGroup: formGroup,
                                                  onQuantityChanged: _syncAllProductsToProvider,
                                                ),
                                              ),
                                              SizedBox(height:10),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.only(
                          top: 5, bottom: 20, left: 20, right: 20),
                      //add border top
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Builder(
                            builder: (context) => SummaryBarSales(
                              isProcessingTotal: FocusScope.of(context).hasFocus,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isBarcodeSearching
                                      ? null
                                      : () {
                                          form.markAllAsTouched();

                                          if (form.valid) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ClientSaleScreen()),
                                            );
                                          }
                                          if (form
                                              .control('products')
                                              .hasError('minLength')) {
                                            errorNotification(
                                                "Debe seleccionar al menos un producto");
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorSchema.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(ticketP.isEdit ? "Continuar Edición" : "Continuar"),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

void showSettingsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        title: const Text("Opciones"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.filter_list),
              title: Text('Filtrar productos'),
              onTap: () {
                // lógica para filtrar
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Configuraciones generales'),
              onTap: () {
                // lógica para ir a configuraciones
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cerrar",
              style: TextStyle(
                color: ColorSchema.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

void _syncFormArrayWithProvider(
    List<TicketDetail> products, FormGroup form, bool incIgv,
    [void Function()? scroll]) {
  final formArray = form.control('products') as FormArray;

  if (formArray.controls.length != products.length) {
    formArray.clear();
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      formArray.add(FormGroup({
        'description': FormControl<String>(
            value: product.descripcion == ''
                ? "Producto ${i + 1}"
                : product.descripcion,
            validators: [Validators.required, Validators.minLength(3)]),
        'price': FormControl<double>(
            value: product.precioVentaUnitario ?? 0,
            validators: [Validators.required, Validators.min(1)]),
        'quantity': FormControl<int>(
            value: (product.cantidad ?? 1).toInt(),
            validators: [Validators.required, Validators.min(1)]),
      }));
    }
    if (scroll != null && formArray.controls.isNotEmpty) {
      scroll();
    }
  } else {
    for (int i = 0; i < formArray.controls.length; i++) {
      final control = formArray.controls[i] as FormGroup;
      final cantidad = (products[i].cantidad ?? 1).toInt();
      final precio = products[i].precioVentaUnitario ?? 0.0;
      final precioUnitario = products[i].valorUnitario ?? 0.0;
      if (control.control('quantity').value != cantidad) {
        control.control('quantity').updateValue(cantidad);
      }
      final precioControl = control.control('price').value;
      if (precioControl != precio && incIgv) {
        control.control('price').updateValue(precio);
      } else if (precioControl != precioUnitario && !incIgv) {
        control.control('price').updateValue(precioUnitario);
      }
      control.control('description').updateValue(
          products[i].descripcion == ''
              ? "Producto ${i + 1}"
              : products[i].descripcion,
          emitEvent: false);
      control.control('quantity').markAsTouched();
      control.control('price').markAsTouched();
      control.control('description').markAsTouched();
    }
  }
}
