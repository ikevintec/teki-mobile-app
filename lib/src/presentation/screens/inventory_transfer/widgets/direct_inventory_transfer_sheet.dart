import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/domain/repositories/inventory_transfer_repository.dart';
import 'package:teki_app/src/presentation/screens/inventory_transfer/widgets/direct_transfer_series_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/inventory_transfer/inventory_transfer_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

class DirectInventoryTransferSheet extends ConsumerStatefulWidget {
  const DirectInventoryTransferSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DirectInventoryTransferSheet(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<DirectInventoryTransferSheet> createState() =>
      _DirectInventoryTransferSheetState();
}

class _DirectInventoryTransferSheetState
    extends ConsumerState<DirectInventoryTransferSheet> {
  static const Color _destinationColor = Color(0xFF2E6B4F);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  int _searchVersion = 0;
  int _productLoadVersion = 0;
  int? _originId;
  int? _destinationId;
  int? _loadingProductId;

  /// false = paso 1 (elegir puntos de venta), true = paso 2 (productos).
  bool _productsStep = false;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _searchError;
  List<Product> _searchResults = const [];
  final List<_SelectedTransferProduct> _selectedProducts = [];

  InventoryTransferRepository get _repository =>
      ref.read(inventoryTransferRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    // El caso habitual es sacar stock del punto de venta donde estás parado.
    final sesion = ref.read(sesionProvider);
    final sessionOfficeId = sesion.office?.id;
    final isAssignable = (sesion.offices ?? const <Office>[]).any(
      (office) => office.id != null && office.id == sessionOfficeId,
    );
    if (isAssignable) _originId = sessionOfficeId;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _disposeSelectedProducts();
    super.dispose();
  }

  // Rebuild para que la "x" del buscador aparezca/desaparezca con el foco.
  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  bool get _canContinue =>
      _originId != null &&
      _destinationId != null &&
      _originId != _destinationId;

  void _continueToProducts() {
    if (!_canContinue) return;
    setState(() => _productsStep = true);
  }

  /// Vuelve al paso 1. Reinicia productos y búsqueda porque el stock y las
  /// series dependen del par origen/destino que se está por cambiar.
  void _backToOfficeStep() {
    _resetProductSelection();
    setState(() => _productsStep = false);
  }

  /// Selecci\u00f3n en dos toques: el primero marca el origen y el segundo el
  /// destino. Tocar un punto ya elegido lo libera; tocar un tercero cuando
  /// ambos est\u00e1n puestos reemplaza el destino.
  void _onOfficeTapped(int officeId) {
    setState(() {
      if (_originId == officeId) {
        _originId = null;
      } else if (_destinationId == officeId) {
        _destinationId = null;
      } else if (_originId == null) {
        _originId = officeId;
      } else {
        _destinationId = officeId;
      }
    });
  }

  void _swapOffices() {
    if (_originId == null && _destinationId == null) return;
    final hadProducts = _selectedProducts.isNotEmpty;
    // Las series disponibles y el stock mostrado dependen del origen, por eso
    // al invertir la dirección hay que volver a elegir los productos.
    _resetProductSelection();
    setState(() {
      final previousOrigin = _originId;
      _originId = _destinationId;
      _destinationId = previousOrigin;
    });
    if (hadProducts) {
      infoNotification(
        'Se limpiaron los productos porque se intercambiaron los puntos de venta',
      );
    }
  }

  void _resetProductSelection() {
    _productLoadVersion++;
    _searchVersion++;
    _debounce?.cancel();
    _debounce = null;
    _searchController.clear();
    _searchFocusNode.unfocus();
    _disposeSelectedProducts();
    _loadingProductId = null;
    _searchResults = const [];
    _searchError = null;
    _isSearching = false;
  }

  void _disposeSelectedProducts() {
    for (final selected in _selectedProducts) {
      selected.quantityController.dispose();
    }
    _selectedProducts.clear();
  }

  bool get _showSearchSuffix =>
      _isSearching ||
      _searchFocusNode.hasFocus ||
      _searchController.text.isNotEmpty;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      _searchVersion++;
      setState(() {
        _searchResults = const [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchProducts(query);
    });
  }

  /// Enter en el teclado: busca de inmediato, sin esperar el debounce.
  void _onSearchSubmitted(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    _searchProducts(query);
  }

  Future<void> _searchProducts(String query) async {
    final version = ++_searchVersion;
    try {
      final result = await _repository.searchProducts(query);
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _searchResults = result
            .where((product) => product.servicio != true)
            .toList();
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _searchError = _cleanError(error);
      });
    }
  }

  Future<void> _selectProduct(Product lightProduct) async {
    _dismissProductSuggestions();

    final productId = lightProduct.id;
    if (productId == null || _originId == null || _destinationId == null) {
      return;
    }
    if (_selectedProducts.any((item) => item.product.id == productId)) {
      infoNotification('El producto ya est\u00e1 en la lista');
      return;
    }

    final loadVersion = ++_productLoadVersion;
    setState(() => _loadingProductId = productId);
    try {
      final product = await _repository.getProductForTransfer(
        productId: productId,
        idPuntoVentaOrigen: _originId!,
        idPuntoVentaDestino: _destinationId!,
      );
      if (!mounted || loadVersion != _productLoadVersion) return;
      if (_selectedProducts.any((item) => item.product.id == productId)) {
        infoNotification('El producto ya est\u00e1 en la lista');
        return;
      }

      final sourceStock = _stockFor(product, _originId!);
      final initialQuantity = sourceStock > 0
          ? math.min(1.0, sourceStock)
          : 1.0;
      setState(() {
        _selectedProducts.add(
          _SelectedTransferProduct(
            product: product,
            quantityController: TextEditingController(
              text: formatDouble(initialQuantity),
            ),
          ),
        );
      });
      if (sourceStock <= 0) {
        warningNotification(
          'El producto no tiene stock disponible en el origen',
        );
      }
    } catch (error) {
      if (mounted && loadVersion == _productLoadVersion) {
        errorNotification(_cleanError(error));
      }
    } finally {
      if (mounted && loadVersion == _productLoadVersion) {
        setState(() => _loadingProductId = null);
      }
    }
  }

  void _dismissProductSuggestions() {
    _searchVersion++;
    _debounce?.cancel();
    _debounce = null;
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _searchResults = const [];
      _searchError = null;
      _isSearching = false;
    });
  }

  Future<void> _openSeriesSelector(_SelectedTransferProduct selected) async {
    final requiredCount = selected.requiredSeriesCount;
    if (requiredCount == null) {
      warningNotification(
        'La cantidad para un producto con series debe ser un n\u00famero entero mayor a cero',
      );
      return;
    }

    final result = await DirectTransferSeriesSheet.show(
      context,
      productName: selected.product.nombre ?? 'Producto',
      requiredCount: requiredCount,
      availableSeries: _availableSeries(selected.product),
      selectedSeries: selected.selectedSeries,
    );
    if (result == null || !mounted) return;
    setState(() => selected.selectedSeries = result);
  }

  void _removeProduct(_SelectedTransferProduct selected) {
    setState(() {
      _selectedProducts.remove(selected);
      selected.quantityController.dispose();
    });
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final validationMessage = _validationMessage();
    if (validationMessage != null) {
      warningNotification(validationMessage);
      return;
    }

    setState(() => _isSubmitting = true);
    final request = DirectInventoryTransferRequest(
      idPuntoVentaOrigen: _originId!,
      idPuntoVentaDestino: _destinationId!,
      comentarioSolicitud: 'Traslado r\u00e1pido desde app m\u00f3vil',
      items: _selectedProducts
          .map(
            (selected) => DirectInventoryTransferItem(
              idProducto: selected.product.id!,
              cantidadSolicitud: selected.quantity,
              lotes: selected.selectedSeries
                  .where((series) => series.id != null)
                  .map(
                    (series) =>
                        DirectInventoryTransferBatch(idLote: series.id!),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );

    try {
      await _repository.createDirectTransfer(request);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      successNotification('Traslado r\u00e1pido realizado correctamente');
    } catch (error) {
      if (mounted) errorNotification(_cleanError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validationMessage() {
    if (_originId == null || _destinationId == null) {
      return 'Selecciona el punto de venta de origen y destino';
    }
    if (_originId == _destinationId) {
      return 'El origen y el destino deben ser diferentes';
    }
    if (_selectedProducts.isEmpty) {
      return 'Agrega al menos un producto';
    }
    for (final selected in _selectedProducts) {
      final sourceStock = _stockFor(selected.product, _originId!);
      if (selected.quantity <= 0) {
        return 'Ingresa una cantidad v\u00e1lida para ${selected.product.nombre ?? 'el producto'}';
      }
      final isSeries = _isSeriesProduct(selected.product);
      final requiredSeries = selected.requiredSeriesCount;
      if (isSeries && requiredSeries == null) {
        return 'La cantidad de ${selected.product.nombre ?? 'el producto'} debe ser un n\u00famero entero';
      }
      if (sourceStock <= 0) {
        return '${selected.product.nombre ?? 'El producto'} no tiene stock en el origen';
      }
      if (selected.quantity > sourceStock) {
        return 'La cantidad de ${selected.product.nombre ?? 'el producto'} supera el stock de origen';
      }
      if (isSeries) {
        final availableSeries = _availableSeries(selected.product);
        if (availableSeries.length < requiredSeries!) {
          return '${selected.product.nombre ?? 'El producto'} solo tiene ${availableSeries.length} series disponibles';
        }
        if (selected.selectedSeries.length != requiredSeries) {
          return 'Selecciona $requiredSeries serie${requiredSeries == 1 ? '' : 's'} para ${selected.product.nombre ?? 'el producto'}';
        }
        final availableIds = availableSeries.map((series) => series.id).toSet();
        final selectedIds = selected.selectedSeries
            .map((series) => series.id)
            .toList();
        if (selectedIds.any((id) => id == null) ||
            selectedIds.toSet().length != selectedIds.length ||
            !selectedIds.every(availableIds.contains)) {
          return 'Vuelve a seleccionar las series de ${selected.product.nombre ?? 'el producto'}';
        }
      }
    }
    return null;
  }

  double _stockFor(Product product, int officeId) {
    for (final inventory in product.inventarios ?? const <Inventory>[]) {
      if (inventory.puntoVenta?.id == officeId) return inventory.stock ?? 0;
    }
    return 0;
  }

  bool _isSeriesProduct(Product product) =>
      product.tipoLote?.toUpperCase() == 'SERIE';

  List<BatchProduct> _availableSeries(Product product) {
    final byId = <int, BatchProduct>{};
    for (final inventory in product.inventarios ?? const <Inventory>[]) {
      if (inventory.puntoVenta?.id != _originId) continue;
      for (final series in inventory.lotes ?? const <BatchProduct>[]) {
        final id = series.id;
        if (id != null &&
            series.tipoLote?.toUpperCase() == 'SERIE' &&
            (series.cantidad ?? 0) > 0) {
          byId[id] = series;
        }
      }
    }
    return byId.values.toList();
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider);
    final offices = _availableOffices(sesion.offices);
    final sessionOfficeId = sesion.office?.id;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        height: availableHeight * 0.94,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                child: _productsStep
                    ? _buildProductsStep(offices, sessionOfficeId)
                    : _buildOfficeStep(offices, sessionOfficeId),
              ),
            ),
            _productsStep ? _buildSubmitArea() : _buildOfficeStepActions(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Paso 1: puntos de venta
  // ---------------------------------------------------------------------------

  Widget _buildOfficeStep(List<Office> offices, int? sessionOfficeId) {
    if (offices.length < 2) {
      return Center(
        key: const ValueKey('step-offices-empty'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                size: 34,
                color: Colors.black.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 10),
              Text(
                'Necesitas al menos dos puntos de venta asignados para hacer un traslado.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 13, color: Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey('step-offices'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Desde dónde y hacia dónde?',
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF30334A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _originId == null
                    ? 'Toca el punto de venta de origen.'
                    : _destinationId == null
                    ? 'Ahora toca el punto de venta de destino.'
                    : 'Toca un punto elegido para liberarlo.',
                style: GoogleFonts.roboto(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            itemCount: offices.length,
            itemBuilder: (context, index) =>
                _buildOfficeCard(offices[index], sessionOfficeId),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficeCard(Office office, int? sessionOfficeId) {
    final isOrigin = office.id == _originId;
    final isDestination = office.id == _destinationId;
    final isSession = office.id != null && office.id == sessionOfficeId;
    final accent = isOrigin
        ? ColorSchema.primaryColor
        : isDestination
        ? _destinationColor
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isSubmitting || office.id == null
              ? null
              : () => _onOfficeTapped(office.id!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            decoration: BoxDecoration(
              color: accent?.withValues(alpha: 0.06) ?? Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent ?? Colors.grey.shade200,
                width: accent != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (accent ?? Colors.black38).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isOrigin
                        ? Icons.logout_rounded
                        : isDestination
                        ? Icons.login_rounded
                        : Icons.store_mall_directory_outlined,
                    size: 18,
                    color: accent ?? Colors.black45,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isSession) ...[
                            _buildSessionDot(),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              office.nombre ??
                                  office.nombreCorto ??
                                  'Punto de venta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.raleway(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isSession
                                    ? ColorSchema.primaryColor
                                    : const Color(0xFF27293D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isSession)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Punto de venta actual de la sesión',
                            style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: ColorSchema.primaryColor.withValues(
                                alpha: 0.85,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (accent != null) ...[
                  const SizedBox(width: 8),
                  _buildRoleBadge(isOrigin ? 'ORIGEN' : 'DESTINO', accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSessionDot() {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: ColorSchema.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorSchema.primaryColor.withValues(alpha: 0.55),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeStepActions() {
    return _buildBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed:
                  _isSubmitting || (_originId == null && _destinationId == null)
                  ? null
                  : _swapOffices,
              icon: const Icon(Icons.swap_vert_rounded, size: 19),
              label: const Text('Intercambiar origen y destino'),
              style: TextButton.styleFrom(
                foregroundColor: ColorSchema.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _canContinue ? _continueToProducts : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.black38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: const Text(
                'Continuar con el traslado',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Paso 2: productos
  // ---------------------------------------------------------------------------

  Widget _buildProductsStep(List<Office> offices, int? sessionOfficeId) {
    return Column(
      key: const ValueKey('step-products'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _buildRoutePill(offices, sessionOfficeId),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _buildProductSearch(),
        ),
        Expanded(
          child: _showSuggestionsPanel
              ? _buildSuggestions()
              : _buildSelectedProductsList(),
        ),
      ],
    );
  }

  /// Fila compacta: origen ⇄ destino ✕. El ⇄ invierte la dirección sin salir
  /// del paso 2; la ✕ vuelve al paso 1 para elegir otros puntos de venta.
  Widget _buildRoutePill(List<Office> offices, int? sessionOfficeId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRouteOffice(
              officeId: _originId,
              offices: offices,
              sessionOfficeId: sessionOfficeId,
              alignment: Alignment.centerLeft,
            ),
          ),
          Material(
            color: ColorSchema.primaryColor.withValues(alpha: 0.1),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              tooltip: 'Intercambiar puntos de venta',
              onPressed: _isSubmitting ? null : _swapOffices,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: ColorSchema.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: _buildRouteOffice(
              officeId: _destinationId,
              offices: offices,
              sessionOfficeId: sessionOfficeId,
              alignment: Alignment.centerRight,
            ),
          ),
          IconButton(
            tooltip: 'Cambiar puntos de venta',
            onPressed: _isSubmitting ? null : _backToOfficeStep,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteOffice({
    required int? officeId,
    required List<Office> offices,
    required int? sessionOfficeId,
    required Alignment alignment,
  }) {
    final office = offices.where((item) => item.id == officeId).firstOrNull;
    final isSession = officeId != null && officeId == sessionOfficeId;
    return Align(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSession) ...[_buildSessionDot(), const SizedBox(width: 5)],
          Flexible(
            child: Text(
              office?.nombreCorto ?? office?.nombre ?? 'Punto de venta',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignment == Alignment.centerRight
                  ? TextAlign.right
                  : TextAlign.left,
              style: GoogleFonts.raleway(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSession
                    ? ColorSchema.primaryColor
                    : const Color(0xFF27293D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _showSuggestionsPanel =>
      _isSearching ||
      _searchError != null ||
      _searchResults.isNotEmpty ||
      _searchController.text.trim().length >= 2;

  Widget _buildSelectedProductsList() {
    if (_selectedProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 34,
                color: Colors.black.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 10),
              Text(
                'Busca y agrega los productos que vas a trasladar.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 13, color: Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          'Productos a trasladar (${_selectedProducts.length})',
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF30334A),
          ),
        ),
        const SizedBox(height: 8),
        ..._selectedProducts.map(_buildSelectedProductCard),
      ],
    );
  }

  Widget _buildBottomBar({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }

  List<Office> _availableOffices(List<Office>? offices) {
    final byId = <int, Office>{};
    for (final office in offices ?? const <Office>[]) {
      if (office.id != null) byId[office.id!] = office;
    }
    return byId.values.toList()
      ..sort((a, b) => (a.nombre ?? '').compareTo(b.nombre ?? ''));
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: ColorSchema.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Traslado r\u00e1pido',
                  style: GoogleFonts.raleway(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF22243A),
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSearch() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      enabled: !_isSubmitting,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: _onSearchSubmitted,
      decoration: InputDecoration(
        hintText: 'Buscar producto...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ColorSchema.primaryColor,
        ),
        // La "x" sigue disponible mientras se busca: si la petición se demora,
        // el usuario puede cerrar el teclado y las sugerencias igual.
        suffixIcon: _showSearchSuffix
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorSchema.primaryColor,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Cerrar búsqueda',
                    onPressed: _dismissProductSuggestions,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ],
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: ColorSchema.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  /// Panel de resultados: ocupa todo el alto disponible bajo el buscador, que
  /// queda fijo arriba, así se ven la mayor cantidad de productos posible.
  Widget _buildSuggestions() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 0, 36, 40),
          child: _isSearching
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ColorSchema.primaryColor,
                  ),
                )
              : Text(
                  _searchError ?? 'No se encontraron productos.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: _searchError != null
                        ? Colors.redAccent
                        : Colors.black45,
                  ),
                ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final product = _searchResults[index];
          final isLoading = _loadingProductId == product.id;
          return ListTile(
            dense: true,
            onTap: isLoading || _loadingProductId != null
                ? null
                : () => _selectProduct(product),
            leading: CircleAvatar(
              backgroundColor: ColorSchema.primaryColor.withValues(alpha: 0.1),
              foregroundColor: ColorSchema.primaryColor,
              child: Text(
                product.nombre?.trim().isNotEmpty == true
                    ? product.nombre!.trim()[0].toUpperCase()
                    : 'P',
              ),
            ),
            title: Text(
              product.nombre ?? 'Producto',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: product.codigo?.isNotEmpty == true
                ? Text(
                    'C\u00f3digo: ${product.codigo}',
                    style: const TextStyle(fontSize: 11),
                  )
                : null,
            trailing: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorSchema.primaryColor,
                    ),
                  )
                : const Icon(
                    Icons.add_circle_outline,
                    color: ColorSchema.primaryColor,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedProductCard(_SelectedTransferProduct selected) {
    final sourceStock = _stockFor(selected.product, _originId!);
    final destinationStock = _stockFor(selected.product, _destinationId!);
    final quantity = selected.quantity;
    final isSeries = _isSeriesProduct(selected.product);
    final requiredSeries = selected.requiredSeriesCount;
    final availableSeriesCount = isSeries
        ? _availableSeries(selected.product).length
        : 0;
    String? quantityError;
    if (quantity <= 0) {
      quantityError = 'Debe ser mayor a 0';
    } else if (isSeries && requiredSeries == null) {
      quantityError = 'Debe ser un n\u00famero entero';
    } else if (sourceStock <= 0) {
      quantityError = 'Sin stock en origen';
    } else if (quantity > sourceStock) {
      quantityError = 'Supera el stock disponible';
    } else if (isSeries && availableSeriesCount < requiredSeries!) {
      quantityError = 'Solo hay $availableSeriesCount series disponibles';
    } else if (isSeries && selected.selectedSeries.length != requiredSeries) {
      quantityError =
          'Selecciona $requiredSeries serie${requiredSeries == 1 ? '' : 's'}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: quantityError == null
              ? Colors.grey.shade200
              : Colors.red.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    selected.product.nombre ?? 'Producto',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF27293D),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Quitar producto',
                  onPressed: _isSubmitting
                      ? null
                      : () => _removeProduct(selected),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStockBox(
                    title: 'Stock origen',
                    stock: sourceStock,
                    isSource: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStockBox(
                    title: 'Stock destino',
                    stock: destinationStock,
                    isSource: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: selected.quantityController,
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: !isSeries,
                    ),
                    inputFormatters: [
                      if (isSeries)
                        FilteringTextInputFormatter.digitsOnly
                      else
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Cantidad a trasladar',
                      errorText: quantityError,
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: ColorSchema.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSeries) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 132,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _openSeriesSelector(selected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorSchema.primaryColor,
                        side: const BorderSide(color: ColorSchema.primaryColor),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                      label: Text(
                        '${selected.selectedSeries.length}/${requiredSeries ?? '-'} series',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (isSeries) ...[
              const SizedBox(height: 7),
              _buildSeriesStatus(
                selected: selected,
                requiredCount: requiredSeries,
                availableCount: availableSeriesCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesStatus({
    required _SelectedTransferProduct selected,
    required int? requiredCount,
    required int availableCount,
  }) {
    final isComplete =
        requiredCount != null &&
        selected.selectedSeries.length == requiredCount &&
        availableCount >= requiredCount;
    final color = isComplete
        ? const Color(0xFF26734D)
        : requiredCount != null && availableCount < requiredCount
        ? Colors.red.shade700
        : const Color(0xFF9A6700);
    final text = requiredCount == null
        ? 'Ingresa una cantidad entera para seleccionar series.'
        : availableCount < requiredCount
        ? 'Series insuficientes: $availableCount disponibles.'
        : isComplete
        ? '$requiredCount serie${requiredCount == 1 ? '' : 's'} seleccionada${requiredCount == 1 ? '' : 's'} correctamente.'
        : 'Selecciona $requiredCount serie${requiredCount == 1 ? '' : 's'} del punto de venta origen.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isComplete
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 10, color: color)),
        ),
      ],
    );
  }

  Widget _buildStockBox({
    required String title,
    required double stock,
    required bool isSource,
  }) {
    final isInvalid = isSource && stock <= 0;
    final color = isInvalid ? Colors.red.shade700 : const Color(0xFF2E6B4F);
    final background = isInvalid
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFEAF7F0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(height: 2),
          Text(
            formatDouble(stock),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitArea() {
    final validationMessage = _validationMessage();
    return _buildBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (validationMessage != null && _selectedProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                validationMessage,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ColorSchema.primaryColor.withValues(
                  alpha: 0.55,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.swap_horiz_rounded),
              label: Text(
                _isSubmitting
                    ? 'Realizando traslado...'
                    : 'Realizar traslado r\u00e1pido',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedTransferProduct {
  final Product product;
  final TextEditingController quantityController;
  List<BatchProduct> selectedSeries;

  _SelectedTransferProduct({
    required this.product,
    required this.quantityController,
    List<BatchProduct>? selectedSeries,
  }) : selectedSeries = selectedSeries ?? [];

  double get quantity =>
      double.tryParse(quantityController.text.trim().replaceAll(',', '.')) ?? 0;

  int? get requiredSeriesCount {
    final value = quantity;
    if (value <= 0 || value != value.truncateToDouble()) return null;
    return value.toInt();
  }
}
