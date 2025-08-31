import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/quantity_selector.dart';
import 'package:teki_app/src/presentation/widgets/form/smart_price_value_accessor.dart';
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
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isPriceFocused = false;
  bool _isDescriptionFocused = false;
  bool _isPriceEditMode = false;

  @override
  void initState() {
    super.initState();
    _priceFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    
    // Inicializar el controller con el valor actual del precio
    final priceControl = widget.formGroup.control('price') as FormControl<double>;
    final initialPrice = priceControl.value ?? 0.0;
    _priceController = TextEditingController(text: initialPrice.toString());
    
    // Inicializar el controller con el valor actual de la descripción
    final descriptionControl = widget.formGroup.control('description') as FormControl<String>;
    final initialDescription = descriptionControl.value ?? '';
    _descriptionController = TextEditingController(text: initialDescription);
    
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
    
    // Listeners para detectar focus y mostrar botón de unfocus en iOS
    _priceFocusNode.addListener(() {
      setState(() {
        _isPriceFocused = _priceFocusNode.hasFocus;
        // Salir del modo edición cuando pierde el focus
        if (!_priceFocusNode.hasFocus) {
          _isPriceEditMode = false;
        }
      });
      
      // Seleccionar todo el texto cuando el campo de precio recibe focus
      if (_priceFocusNode.hasFocus) {
        _priceController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _priceController.text.length,
        );
      }
    });
    
        _descriptionFocusNode.addListener(() {
      setState(() {
        _isDescriptionFocused = _descriptionFocusNode.hasFocus;
      });

      // Seleccionar todo el texto cuando el campo de descripción recibe focus
      if (_descriptionFocusNode.hasFocus) {
        _descriptionController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _descriptionController.text.length,
        );
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

  void _onQuantityChanged(AbstractControl<int> control) {
    control.markAsTouched();
    final value = control.value ?? 1;
    ref
        .read(productSaleProvider.notifier)
        .setCantidadProductSale(widget.index, value.toDouble());
  }

  @override
  void dispose() {
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final provider = ref.watch(productSaleProvider);

    final card = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
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
                        textInputAction: TextInputAction.next,
                        focusNode: _descriptionFocusNode,
                        controller: _descriptionController,
                        onSubmitted: (control) {
                          // Cambiar focus al campo de precio al presionar Enter
                          _priceFocusNode.requestFocus();
                        },
                        style: const TextStyle(
                          color: Colors.black, // Texto en color negro
                        ),
                        decoration: InputDecoration(
                          isDense: true, // Reduce altura vertical
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, // ↓ Espacio vertical mínimo
                          ),
                          suffixIcon: (isIos && _isDescriptionFocused)
                              ? GestureDetector(
                                  onTap: () => FocusScope.of(context).unfocus(),
                                  child: const Icon(
                                    Icons.keyboard_hide,
                                    size: 15,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
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
                        // Control de precio
                        SizedBox(
                          width: 160,
                          child: _isPriceEditMode
                            ? ReactiveTextField<double>(
                                formControlName: 'price',
                                valueAccessor: SmartPriceValueAccessor(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.done,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                focusNode: _priceFocusNode,
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: provider.incIgv
                                      ? 'Precio Venta'
                                      : 'Valor unitario',
                                  prefixText: formatExchange(
                                      moneda: provider.currency!
                                          .codigoMoneda!), // ← Aquí colocas tu prefijo
                                  suffixIcon: (isIos && _isPriceFocused)
                                      ? GestureDetector(
                                          onTap: () => FocusScope.of(context).unfocus(),
                                          child: const Icon(
                                            Icons.keyboard_hide,
                                            size: 15,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : null,
                                ),
                                onSubmitted: (control) {
                                  // Cerrar teclado al presionar Done
                                  FocusScope.of(context).unfocus();
                                },
                                validationMessages: {
                                  ValidationMessage.min: (error) => 'Mínimo 1',
                                  ValidationMessage.required: (error) => 'Precio requerido',
                                },
                              )
                            : GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPriceEditMode = true;
                                  });
                                  // Dar focus al campo después de un frame
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _priceFocusNode.requestFocus();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                                  child: ReactiveFormConsumer(
                                    builder: (context, form, child) {
                                      final priceControl = form.control('price') as FormControl<double>;
                                      final priceValue = priceControl.value ?? 0.0;
                                      final hasError = priceControl.hasErrors && priceControl.touched;

                                      return Text(
                                        '${formatExchange(moneda: provider.currency!.codigoMoneda!)} ${priceValue.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: hasError ? Colors.red : Colors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                        ),
                        // Control de cantidad
                        QuantityControl(
                          formGroup: widget.formGroup,
                          onQuantityChanged: () {
                            final quantityControl = widget.formGroup.control('quantity') as FormControl<int>;
                            _onQuantityChanged(quantityControl);
                          },
                        ),
                      ],
                    ),
                  ],
                )),

              ],
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: 0,
          bottom: 0,
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

    // Divider casi imperceptible entre items
    return Column(
      children: [
        card,
        Divider(
          height: 2,
          thickness: 0.5,
          color: Colors.grey[200],
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }
}

// Widget personalizado para el control de cantidad
class QuantityControl extends StatefulWidget {
  final FormGroup formGroup;
  final VoidCallback onQuantityChanged;

  const QuantityControl({
    Key? key,
    required this.formGroup,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  State<QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<QuantityControl> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final quantityControl = widget.formGroup.control('quantity') as FormControl<int>;
    _controller = TextEditingController(text: (quantityControl.value ?? 1).toString());
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateQuantity(int newValue) {
    if (newValue > 0) {
      final quantityControl = widget.formGroup.control('quantity') as FormControl<int>;
      quantityControl.value = newValue;
      _controller.text = newValue.toString();
      widget.onQuantityChanged();
    }
  }

  void _increment() {
    setState(() {
      final quantityControl = widget.formGroup.control('quantity') as FormControl<int>;
      final currentValue = quantityControl.value ?? 1;
      _updateQuantity(currentValue + 1);
    });
  }

  void _decrement() {
    setState(() {
      final quantityControl = widget.formGroup.control('quantity') as FormControl<int>;
      final currentValue = quantityControl.value ?? 1;
      if (currentValue > 1) {
        _updateQuantity(currentValue - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón menos
            Material(
              color: ColorSchema.primaryColor,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                onTap: _decrement,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 24,
                  height: 24,
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Campo de entrada
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: ColorSchema.primaryColor, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                onChanged: (value) {
                  setState(() {
                    final intValue = int.tryParse(value);
                    if (intValue != null && intValue > 0) {
                      _updateQuantity(intValue);
                    } else if (value.isEmpty || intValue == 0) {
                      _updateQuantity(1);
                    }
                  });
                },
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 4),
            // Botón más
            Material(
              color: ColorSchema.primaryColor,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                onTap: _increment,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 24,
                  height: 24,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
