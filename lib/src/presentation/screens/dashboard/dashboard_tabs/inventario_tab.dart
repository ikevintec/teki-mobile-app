import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/screens/inventory/inventory_sections/inventory_list_section.dart';
import 'package:teki_app/src/presentation/screens/inventory_production/inventory_production_screen.dart';
import 'package:teki_app/src/presentation/widgets/barcode_scanner/barcode_scanner_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/inventory/inventory_provider.dart';
import 'package:teki_app/src/utils/constants.dart';

class InventarioTab extends ConsumerStatefulWidget {
  final ValueNotifier<int> refreshNotifier;

  const InventarioTab({super.key, required this.refreshNotifier});

  @override
  ConsumerState<InventarioTab> createState() => _InventarioTabState();
}

class _InventarioTabState extends ConsumerState<InventarioTab> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    widget.refreshNotifier.addListener(_onRefresh);
    Future.microtask(() {
      if (!mounted) return;
      final idPuntoVenta = ref.read(sesionProvider).office?.id;
      if (idPuntoVenta != null) {
        ref.read(inventoryProvider.notifier).loadInventory(idPuntoVenta);
      }
    });
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_onRefresh);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _debounce?.cancel();
    final idPuntoVenta = ref.read(sesionProvider).office?.id;
    if (idPuntoVenta == null) return;
    // Conserva la búsqueda activa: este refresh también se dispara al cerrar
    // bottom sheets (opciones/historial), y limpiarla borraba los resultados.
    final search = _searchController.text.trim();
    if (search.isNotEmpty) {
      ref.read(inventoryProvider.notifier).searchInventory(search);
    } else {
      ref.read(inventoryProvider.notifier).loadInventory(idPuntoVenta);
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      ref.read(inventoryProvider.notifier).searchInventory(value);
    });
  }

  Future<void> _onScanInventory() async {
    final code = await BarcodeScannerSheet.show(context);
    if (code != null && code.isNotEmpty) {
      _debounce?.cancel();
      _searchController.text = code;
      setState(() {});
      ref.read(inventoryProvider.notifier).searchInventory(code);
    }
  }

  Future<void> _pullToRefresh() async {
    _debounce?.cancel();
    setState(() => _isRefreshing = true);
    try {
      final currentSearch = _searchController.text.trim();
      final idPuntoVenta = ref.read(sesionProvider).office?.id;
      if (idPuntoVenta == null) return;
      if (currentSearch.isNotEmpty) {
        await ref.read(inventoryProvider.notifier).searchInventory(currentSearch);
      } else {
        await ref.read(inventoryProvider.notifier).loadInventory(idPuntoVenta);
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final isLoading = state.isLoading && state.items.isEmpty;
    final hasError = !state.isLoading && state.errorMessage != null && state.items.isEmpty;

    ref.listen<InventoryState>(inventoryProvider, (previous, next) {
      if (next.filterGlobal == null && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });

    return Column(
      children: [
        // Buscador + scanner
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      hintStyle:
                          const TextStyle(fontSize: 14, color: Colors.black38),
                      prefixIcon: const Icon(Icons.search,
                          color: ColorSchema.primaryColor, size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: Colors.black38),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: ColorSchema.primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _onScanInventory,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: ColorSchema.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const InventoryProductionScreen()),
                ),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ColorSchema.primaryColor),
                  ),
                  child: const Icon(Icons.precision_manufacturing_outlined,
                      color: ColorSchema.primaryColor, size: 22),
                ),
              ),
            ],
          ),
        ),
        // Lista con RefreshIndicator
        Expanded(
          child: RefreshIndicator(
            color: ColorSchema.primaryColor,
            onRefresh: _pullToRefresh,
            child: isLoading && !_isRefreshing
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: ColorSchema.primaryColor,
                              strokeWidth: 2,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Cargando inventario...',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : hasError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No hay conexión',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _onRefresh,
                              child: Text(
                                'Reintentar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ColorSchema.primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: ColorSchema.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : InventoryListSection(items: state.items),
          ),
        ),
      ],
    );
  }
}
