import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/data/static/lists.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/modal_series_config.dart';
import 'package:teki_app/src/presentation/widgets/form/smart_price_value_accessor.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductItemCard extends ConsumerStatefulWidget {
  final TicketDetail productTicketDetail;
  final int index;
  final FormGroup formGroup;
  final VoidCallback? onQuantityChanged;

  const ProductItemCard({
    super.key,
    required this.productTicketDetail,
    required this.index,
    required this.formGroup,
    this.onQuantityChanged,
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

  @override
  void dispose() {
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Widget _buildProductAvatar() {
    final imageUrl = widget.productTicketDetail.producto?.imagenPorDefecto?.imagen;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
          },
          errorBuilder: (c, e, s) => _buildInitialCircle(),
        ),
      );
    }
    return _buildInitialCircle();
  }

  // ── Tipo de afectación IGV (catálogo 07, paridad web) ────────────────────

  String get _afectacionActual =>
      widget.productTicketDetail.codigoTipoAfectacionIgv ?? '10';

  /// Default del punto de venta; a falta de config, Gravado - Op. Onerosa.
  String get _afectacionPorDefecto =>
      ref.read(sesionProvider).office?.codigoAfectacionPorDefecto ?? '10';

  static const _familiasIgv = {
    '1001': 'Gravado',
    '1003': 'Exonerado',
    '1002': 'Inafecto',
    '1000': 'Exportación',
    '1004': 'Gratuita',
  };

  Map<String, dynamic> get _afectacionInfo => catalogo07.firstWhere(
        (e) => e['codigo'] == _afectacionActual,
        orElse: () => catalogo07.first,
      );

  /// Fila discreta bajo el precio (mismo patrón que "Ver series"): gris
  /// cuando es la afectación por defecto, azul cuando el item es especial.
  Widget _buildAfectacionIgvRow() {
    final esDefault = _afectacionActual == _afectacionPorDefecto;
    final grupo = _afectacionInfo['codigoRelacionado'] as String;
    final familia = _familiasIgv[grupo] ?? 'Gravado';
    final esGratuita = grupo == '1004';
    final color = esDefault ? Colors.grey.shade500 : ColorSchema.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showAfectacionSheet,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.percent_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              esGratuita ? 'IGV: $familia · no suma al total' : 'IGV: $familia',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: esDefault ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAfectacionSheet() {
    final actual = _afectacionActual;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tipo de IGV (afectación)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade200),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final grupo in ['1001', '1003', '1002', '1000', '1004']) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _familiasIgv[grupo]!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      for (final item in catalogo07
                          .where((e) => e['codigoRelacionado'] == grupo))
                        InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            ref
                                .read(productSaleProvider.notifier)
                                .setAfectacionIgvProductSale(
                                    widget.index, item['codigo'] as String);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 11),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['descripcion'] as String,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: item['codigo'] == actual
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: item['codigo'] == actual
                                          ? ColorSchema.primaryColor
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (item['codigo'] == actual)
                                  const Icon(Icons.check_rounded,
                                      size: 18, color: ColorSchema.primaryColor),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialCircle() {
    final label = widget.productTicketDetail.descripcion?.isNotEmpty == true
        ? widget.productTicketDetail.descripcion![0].toUpperCase()
        : 'P';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: ColorSchema.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: ColorSchema.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final provider = ref.watch(productSaleProvider);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 44, 12),
              child: ReactiveForm(
                formGroup: widget.formGroup,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProductAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.productTicketDetail.producto != null)
                            Text(
                              widget.productTicketDetail.producto!.nombre ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widget.productTicketDetail.producto == null)
                            ReactiveTextField<String>(
                              formControlName: 'description',
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              focusNode: _descriptionFocusNode,
                              controller: _descriptionController,
                              onSubmitted: (_) => _priceFocusNode.requestFocus(),
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                suffixIcon: (isIos && _isDescriptionFocused)
                                    ? GestureDetector(
                                        onTap: () => FocusScope.of(context).unfocus(),
                                        child: const Icon(Icons.keyboard_hide, size: 15, color: Colors.grey),
                                      )
                                    : null,
                              ),
                              validationMessages: {
                                ValidationMessage.minLength: (_) => 'Mínimo 3 caracteres',
                                ValidationMessage.required: (_) => 'Nombre requerido',
                              },
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _isPriceEditMode
                                  ? SizedBox(
                                      width: 150,
                                      child: ReactiveTextField<double>(
                                        formControlName: 'price',
                                        valueAccessor: SmartPriceValueAccessor(),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textInputAction: TextInputAction.done,
                                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                        focusNode: _priceFocusNode,
                                        controller: _priceController,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelText: provider.incIgv ? 'Precio Venta' : 'Valor unitario',
                                          prefixText: formatExchange(moneda: provider.currency!.codigoMoneda!),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: ColorSchema.primaryColor),
                                          ),
                                          suffixIcon: (isIos && _isPriceFocused)
                                              ? GestureDetector(
                                                  onTap: () => FocusScope.of(context).unfocus(),
                                                  child: const Icon(Icons.keyboard_hide, size: 15, color: Colors.grey),
                                                )
                                              : null,
                                        ),
                                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                                        validationMessages: {
                                          ValidationMessage.min: (_) => 'Mínimo 0.01',
                                          ValidationMessage.required: (_) => 'Precio requerido',
                                        },
                                      ),
                                    )
                                  : GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        // Editar el precio del item requiere permiso (paridad web)
                                        if (!ref
                                            .read(sesionProvider)
                                            .hasPermission('VENTAS_EDITAR_PRECIO')) {
                                          return;
                                        }
                                        setState(() => _isPriceEditMode = true);
                                        WidgetsBinding.instance.addPostFrameCallback((_) => _priceFocusNode.requestFocus());
                                      },
                                      child: ReactiveFormConsumer(
                                        builder: (context, form, _) {
                                          final priceControl = form.control('price') as FormControl<double>;
                                          final priceValue = priceControl.value ?? 0.0;
                                          final hasError = priceControl.hasErrors && priceControl.touched;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: hasError
                                                  ? Colors.red.withValues(alpha: 0.08)
                                                  : ColorSchema.primaryColor.withValues(alpha: 0.09),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${formatExchange(moneda: provider.currency!.codigoMoneda!)} ${priceValue.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: hasError ? Colors.red : ColorSchema.primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 11,
                                                  color: hasError
                                                      ? Colors.red
                                                      : ColorSchema.primaryColor.withValues(alpha: 0.5),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                              QuantityControl(
                                formGroup: widget.formGroup,
                                onQuantityChanged: widget.onQuantityChanged ?? () {},
                                locked: widget.productTicketDetail.comandaDetalle != null,
                              ),
                            ],
                          ),
                          if (_requiresSeriesValidation(widget.productTicketDetail.producto))
                            Builder(builder: (context) {
                              final cantidad = (widget.productTicketDetail.cantidad ?? 1).toInt();
                              final seleccionadas = (widget.productTicketDetail.lotes ?? []).length;
                              final valido = seleccionadas == cantidad;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: GestureDetector(
                                  onTap: () => showSeriesConfigSheet(
                                    context,
                                    ticketDetail: widget.productTicketDetail,
                                    index: widget.index,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        valido ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                        size: 13,
                                        color: valido ? ColorSchema.primaryColor : Colors.red.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        valido
                                            ? 'Ver series ($seleccionadas/$cantidad)'
                                            : 'Series requeridas ($seleccionadas/$cantidad)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: valido ? ColorSchema.primaryColor : Colors.red.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          // La afectación de comandas viene fijada por el
                          // producto del restaurante: no se edita aquí.
                          if (widget.productTicketDetail.comandaDetalle == null)
                            _buildAfectacionIgvRow(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(-_shakeAnimation.value, 0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _shakeController.forward().then((_) => _shakeController.reverse()),
                        child: const SizedBox(
                          width: 36,
                          child: Icon(Icons.chevron_left_rounded, size: 22, color: ColorSchema.primaryColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

/// Muestra la cantidad sin ".0" cuando es entera (el accessor por defecto
/// de FormControl&lt;double&gt; renderizaría "1.0") y parsea decimales al escribir.
class _QuantityValueAccessor extends ControlValueAccessor<double, String> {
  @override
  String modelToViewValue(double? modelValue) {
    if (modelValue == null) return '';
    return modelValue % 1 == 0
        ? modelValue.toInt().toString()
        : modelValue.toString();
  }

  @override
  double? viewToModelValue(String? viewValue) =>
      (viewValue == null || viewValue.isEmpty) ? null : double.tryParse(viewValue);
}

// Widget personalizado para el control de cantidad
class QuantityControl extends ConsumerStatefulWidget {
  final FormGroup formGroup;
  final VoidCallback onQuantityChanged;
  final bool locked;

  const QuantityControl({
    Key? key,
    required this.formGroup,
    required this.onQuantityChanged,
    this.locked = false,
  }) : super(key: key);

  @override
  ConsumerState<QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends ConsumerState<QuantityControl> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateQuantity(double newValue) {
    if (newValue > 0) {
      final quantityControl = widget.formGroup.control('quantity') as FormControl<double>;
      quantityControl.updateValue(newValue);
      widget.onQuantityChanged();
    }
  }

  void _increment() {
    final quantityControl = widget.formGroup.control('quantity') as FormControl<double>;
    final currentValue = quantityControl.value ?? 1;
    _updateQuantity(currentValue + 1);
  }

  void _decrement() {
    final quantityControl = widget.formGroup.control('quantity') as FormControl<double>;
    final currentValue = quantityControl.value ?? 1;
    // El guard de _updateQuantity (> 0) impide bajar a 0 o negativos;
    // con decimales sí permite p.ej. 1.5 → 0.5.
    _updateQuantity(currentValue - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      final quantityControl = widget.formGroup.control('quantity') as FormControl<double>;
      return ReactiveFormConsumer(
        builder: (context, form, _) {
          final qtyValue = quantityControl.value ?? 1;
          final qty = qtyValue % 1 == 0 ? qtyValue.toInt().toString() : qtyValue.toString();
          return Container(
            width: 120,
            height: 32,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'x$qty',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return SizedBox(
      width: 120,
      height: 32,
      child: ReactiveForm(
        formGroup: widget.formGroup,
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
                  child: SizedBox(
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
                child: ReactiveTextField<double>(
                  formControlName: 'quantity',
                  focusNode: _focusNode,
                  valueAccessor: _QuantityValueAccessor(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: ColorSchema.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onSubmitted: (control) {
                    widget.onQuantityChanged();
                  },
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
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
                  child: SizedBox(
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
      ),
    );
  }
}

bool _requiresSeriesValidation(Product? product) {
  if (product == null) return false;
  return product.tipoLote == 'SERIE' &&
      (product.validacionLote ?? false) &&
      (product.tipoProducto == 'ARTICULO' || product.tipoProducto == 'INSUMO');
}
