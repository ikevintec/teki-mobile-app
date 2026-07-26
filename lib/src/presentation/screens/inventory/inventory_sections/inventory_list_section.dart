import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/presentation/screens/inventory/widgets/inventory_movements_sheet.dart';
import 'package:teki_app/src/providers/inventory/inventory_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

/// Estado de stock de un ítem para el semáforo de la lista.
enum _EstadoStock { normal, bajo, agotado }

_EstadoStock _estadoDe(Inventory inv) {
  final stock = inv.stock ?? 0;
  if (stock <= 0) return _EstadoStock.agotado;
  final minimo = inv.producto?.inventarioMinimo;
  if (minimo != null && minimo > 0 && stock <= minimo) {
    return _EstadoStock.bajo;
  }
  return _EstadoStock.normal;
}

class InventoryListSection extends ConsumerStatefulWidget {
  final List<Inventory> items;

  const InventoryListSection({super.key, required this.items});

  @override
  ConsumerState<InventoryListSection> createState() =>
      _InventoryListSectionState();
}

class _InventoryListSectionState extends ConsumerState<InventoryListSection> {
  late final ScrollController _scrollController;

  /// Filtro por estado de stock (client-side sobre lo cargado).
  _EstadoStock? _filtro;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMore() {
    Future.microtask(() {
      if (!ref.read(inventoryProvider).isLoading) {
        ref.read(inventoryProvider.notifier).loadNextPage();
      }
    });
  }

  void _openMovementsSheet(Inventory inventory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: InventoryMovementsSheet(inventory: inventory),
      ),
    );
  }

  Future<void> _ajustarInventario(Inventory item) async {
    await Get.toNamed(
      AppRoutes.inventoryAdjustmentCreate,
      arguments: {'inventory': item},
    );
    if (!mounted) return;
    final idPuntoVenta = ref.read(inventoryProvider).idPuntoVenta;
    if (idPuntoVenta != null) {
      ref.read(inventoryProvider.notifier).loadInventory(idPuntoVenta);
    }
  }

  /// Acciones del ítem (patrón bottom sheet de la app): reemplaza a los
  /// íconos por fila, que eran crípticos y fáciles de tocar por error.
  void _openAccionesSheet(Inventory item) {
    final puedeAjustar = item.producto != null &&
        ref.read(sesionProvider).hasPermission('INVENTARIO_AJUSTAR');
    final estado = _estadoDe(item);
    final stock = formatDouble(item.stock ?? 0);
    final unidad = _unidadDe(item);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.producto?.nombre ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.raleway(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    switch (estado) {
                      _EstadoStock.agotado => '$stock $unidad · agotado',
                      _EstadoStock.bajo =>
                        '$stock $unidad · stock bajo (mín. ${formatDouble(item.producto!.inventarioMinimo!)})',
                      _ => '$stock $unidad disponibles',
                    },
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      color: switch (estado) {
                        _EstadoStock.agotado => Colors.red.shade600,
                        _EstadoStock.bajo => Colors.orange.shade800,
                        _ => Colors.grey.shade600,
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade200),
            _accionTile(
              icon: Icons.sync_alt_rounded,
              label: 'Ver historial de movimientos',
              onTap: () {
                Navigator.of(ctx).pop();
                _openMovementsSheet(item);
              },
            ),
            if (puedeAjustar)
              _accionTile(
                icon: Icons.edit_note_rounded,
                label: 'Ajustar stock',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _ajustarInventario(item);
                },
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _accionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: ColorSchema.primaryColor),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorSchema.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _unidadDe(Inventory inv) {
    final u = inv.producto?.unidad;
    if (u?.abreviatura?.isNotEmpty == true) return u!.abreviatura!;
    if (u?.codigo?.isNotEmpty == true) return u!.codigo!;
    return '';
  }

  List<Inventory> get _filtrados => _filtro == null
      ? widget.items
      : widget.items.where((i) => _estadoDe(i) == _filtro).toList();

  Widget _buildFiltros() {
    final agotados =
        widget.items.where((i) => _estadoDe(i) == _EstadoStock.agotado).length;
    final bajos =
        widget.items.where((i) => _estadoDe(i) == _EstadoStock.bajo).length;

    Widget chip(String label, _EstadoStock? valor, Color? color) {
      final activo = _filtro == valor;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _filtro = valor),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: activo
                  ? (color ?? ColorSchema.primaryColor)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activo
                    ? (color ?? ColorSchema.primaryColor)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activo ? Colors.white : (color ?? Colors.grey.shade700),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('Todos', null, null),
            if (agotados > 0)
              chip('Agotados ($agotados)', _EstadoStock.agotado,
                  Colors.red.shade600),
            if (bajos > 0)
              chip('Stock bajo ($bajos)', _EstadoStock.bajo,
                  Colors.orange.shade800),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = ref.watch(inventoryProvider).last;

    if (widget.items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No se encontraron ítems de inventario',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final items = _filtrados;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: items.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return _buildFiltros();

        if (index == items.length + 1) {
          // Con filtro activo no se pagina (se filtra sobre lo cargado).
          if (_filtro != null) {
            return const SizedBox(height: 30);
          }
          if (isLast) {
            return const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'No hay más ítems',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            );
          } else {
            _loadMore();
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorSchema.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }
        }

        final item = items[index - 1];
        return _InventoryCard(
          inventory: item,
          onTap: () => _openAccionesSheet(item),
        );
      },
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Inventory inventory;
  final VoidCallback onTap;

  const _InventoryCard({required this.inventory, required this.onTap});

  /// Fecha corta y humana: hoy HH:mm, ayer, hace N días o dd/MM/yy.
  static String? _fechaRelativa(DateTime? fecha) {
    if (fecha == null) return null;
    final ahora = DateTime.now();
    final dias = DateTime(ahora.year, ahora.month, ahora.day)
        .difference(DateTime(fecha.year, fecha.month, fecha.day))
        .inDays;
    if (dias <= 0) return 'hoy ${DateFormat('HH:mm').format(fecha)}';
    if (dias == 1) return 'ayer';
    if (dias < 30) return 'hace $dias días';
    return DateFormat('dd/MM/yy').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final stock = inventory.stock ?? 0;
    final estado = _estadoDe(inventory);
    final fecha = _fechaRelativa(inventory.fechaActualizacion);
    final codigo = inventory.producto?.codigo;

    final (Color? tintBg, Color? tintBorder, Color stockColor, String? etiqueta) =
        switch (estado) {
      _EstadoStock.agotado => (
          const Color(0xFFFFF5F5),
          Colors.red.shade200,
          Colors.red.shade600,
          'AGOTADO'
        ),
      _EstadoStock.bajo => (
          const Color(0xFFFFF8E1),
          Colors.orange.shade200,
          Colors.orange.shade800,
          'STOCK BAJO'
        ),
      _ => (null, null, Colors.black54, null),
    };

    final subtitulo = [
      if (codigo != null && codigo.isNotEmpty) codigo,
      if (estado == _EstadoStock.bajo &&
          inventory.producto?.inventarioMinimo != null)
        'mín. ${formatDouble(inventory.producto!.inventarioMinimo!)}',
      if (fecha != null) 'act. $fecha',
    ].join(' · ');

    return Card(
      elevation: 0.1,
      color: tintBg ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: tintBorder != null
            ? BorderSide(color: tintBorder)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Imagen del producto
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: () {
                    final url = inventory.producto?.imagenPorDefecto?.imagen;
                    if (url != null && url.isNotEmpty) {
                      return Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Image.asset(
                            'assets/images/gif/loader.gif',
                            fit: BoxFit.cover,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/products/icon.png',
                          fit: BoxFit.contain,
                        ),
                      );
                    }
                    return Image.asset(
                      'assets/images/products/icon.png',
                      fit: BoxFit.contain,
                    );
                  }(),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inventory.producto?.nombre ?? '-',
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitulo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: estado == _EstadoStock.normal
                              ? Colors.black38
                              : stockColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stock con semáforo
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatDouble(stock),
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: stockColor,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _InventoryListSectionState._unidadDe(inventory),
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  if (etiqueta != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      etiqueta,
                      style: GoogleFonts.roboto(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: stockColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
