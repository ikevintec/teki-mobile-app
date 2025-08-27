import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/modal_product_view.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/quantity_selector.dart';
import 'package:teki_app/src/presentation/widgets/form/smart_price_value_accessor.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductItemCard extends ConsumerStatefulWidget {
  final TicketDetail productTicketDetail;
  final int index;
  final FormGroup formGroup;

  const ProductItemCard({
    super.key,
    required this.productTicketDetail,
    required this.index,
    required this.formGroup,
  });

  @override
  ConsumerState<ProductItemCard> createState() => _ProductItemCardState();
}

class _ProductItemCardState extends ConsumerState<ProductItemCard>
    with TickerProviderStateMixin {
  late FocusNode _priceFocusNode;
  late FocusNode _descriptionFocusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _priceFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    
    // Configurar animación de shake
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOutSine),
    );
    
    // Hacer una animación inicial sutil para llamar la atención
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _shakeController.forward().then((_) {
          _shakeController.reverse();
        });
      }
    });
    
    // Listener para detectar cuando el campo de precio pierde el focus
    _priceFocusNode.addListener(() {
      if (!_priceFocusNode.hasFocus) {
        _onPriceChanged(widget.formGroup.control('price') as AbstractControl<double>);
      }
    });
    
    // Listener para detectar cuando el campo de descripción pierde el focus
    _descriptionFocusNode.addListener(() {
      if (!_descriptionFocusNode.hasFocus) {
        _onDescriptionChanged(widget.formGroup.control('description') as AbstractControl<String>);
      }
    });
  }

  void _onPriceChanged(AbstractControl<double> control) {
    control.markAsTouched();
    final value = control.value;
    ref
        .read(productSaleProvider.notifier)
        .setPrecioProductSale(widget.index, value ?? 0.0);
  }

  void _onDescriptionChanged(AbstractControl<String> control) {
    control.markAsTouched();
    final value = control.value;
    ref
        .read(productSaleProvider.notifier)
        .setDescriptionProductSale(widget.index, value ?? '');
  }

  @override
  void dispose() {
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(productSaleProvider.select((state) => (
      currency: state.currency,
      incIgv: state.incIgv,
    )));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          // margin: const EdgeInsets.only(bottom: 15, top: 10, right: 5),
          padding: const EdgeInsets.only(
            left: 30,
            right: 35,
            top: 0,
          ),
          child: ReactiveForm(
            formGroup: widget.formGroup,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorSchema.primaryColor, // color de fondo
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.productTicketDetail.descripcion != ''
                        ? widget.productTicketDetail.descripcion![0]
                            .toUpperCase()
                        : 'P',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (widget.productTicketDetail.producto != null)
                      Text(
                        widget.productTicketDetail.producto!.nombre ?? '',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis),
                      ),
                    if (widget.productTicketDetail.producto == null)
                      ReactiveTextField<String>(
                        formControlName: 'description',
                        keyboardType: TextInputType.name,
                        focusNode: _descriptionFocusNode,
                        onSubmitted: _onDescriptionChanged,
                        style: const TextStyle(
                          color: Colors.black, // Texto en color negro
                        ),
                        decoration: const InputDecoration(
                          isDense: true, // Reduce altura vertical
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0, // ↓ Espacio vertical mínimo
                          ),
                        ),
                        validationMessages: {
                          ValidationMessage.minLength: (error) => 'Minimo 3 caracteres',
                          ValidationMessage.required: (error) =>
                              'Nombre requerido',
                        },
                      ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 120,
                          child: ReactiveTextField<double>(
                            formControlName: 'price',
                            valueAccessor: SmartPriceValueAccessor(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                            focusNode: _priceFocusNode,
                            decoration: InputDecoration(
                              labelText: provider.incIgv
                                  ? 'Precio Venta'
                                  : 'Valor unitario',
                              prefixText: formatExchange(
                                  moneda: provider.currency!
                                      .codigoMoneda!), // ← Aquí colocas tu prefijo
                            ),
                            onSubmitted: _onPriceChanged,
                            validationMessages: {
                              ValidationMessage.min: (error) => 'Minimo 0',
                            },
                          ),
                        ),
                        Row(
                          children: [
                            if (widget.productTicketDetail.producto != null)
                              IconButton(
                                onPressed: () {
                                  showCustomModal(
                                      context: context,
                                      child: ModalProductView(
                                          product: widget
                                              .productTicketDetail.producto!),
                                      tittle: "Ver Producto",
                                      allowButtons: false);
                                },
                                icon: Icon(Icons.visibility,
                                    color: ColorSchema.primaryColor, size: 15),
                              ),
                            const SizedBox(width: 10),
                            Icon(Icons.settings,
                                color: ColorSchema.primaryColor, size: 15),
                          ],
                        ),
                      ],
                    ),
                  ],
                )),
                const SizedBox(width: 10),
                ReactiveQuantitySelector(
                  formControlName: 'quantity',
                  onChanged: (value) {
                    if (value.value == null || value.value! < 1) {
                      return;
                    }
                    ref
                        .read(productSaleProvider.notifier)
                        .setCantidadProductSale(
                            widget.index, (value.value ?? 1).toDouble());
                  },
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: 50,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-_shakeAnimation.value, 0),
                child: Material(
                  color: Colors.transparent,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(30)),
                  child: InkWell(
                    borderRadius:
                        const BorderRadius.horizontal(left: Radius.circular(30)),
                    onTap: () {
                      // Activar animación de shake para indicar que puede deslizar
                      _shakeController.forward().then((_) {
                        _shakeController.reverse();
                      });
                    },
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Colors.redAccent),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
