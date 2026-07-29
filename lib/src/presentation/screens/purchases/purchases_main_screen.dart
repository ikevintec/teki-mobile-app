import 'dart:async';
import 'package:teki_app/src/presentation/widgets/floating_action_button/custom_floating_action_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/presentation/screens/purchases/create_purchase_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/purchases/purchases_list_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class PurchasesMainScreen extends ConsumerStatefulWidget {
  const PurchasesMainScreen({super.key});

  @override
  ConsumerState<PurchasesMainScreen> createState() =>
      _PurchasesMainScreenState();
}

class _PurchasesMainScreenState extends ConsumerState<PurchasesMainScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  static final _fmtFecha = DateFormat('dd/MM/yy HH:mm', 'es_PE');
  static final _fmtMonto = NumberFormat('#,##0.00', 'es_PE');
  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchasesListProvider.notifier).loadFirstPage();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(purchasesListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(purchasesListProvider.notifier).setSearch(value);
    });
  }

  Future<void> _nuevaCompra() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePurchaseScreen()),
    );
    if (mounted) ref.read(purchasesListProvider.notifier).refresh();
  }

  Future<void> _anular(Purchase compra) async {
    final controller = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '¿Anular la compra ${compra.comprobante ?? ''}? Se revertirá el ingreso de stock.',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Motivo de anulación',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Anular')),
        ],
      ),
    );
    if (confirmar != true) return;
    if (controller.text.trim().isEmpty) {
      warningNotification('Ingresa el motivo de anulación', fromTop: false);
      return;
    }
    try {
      await ref
          .read(purchasesListProvider.notifier)
          .cancel(compra.id!, controller.text.trim());
      successNotification('Compra anulada', fromTop: false);
    } catch (e) {
      errorNotification(e.toString(), fromTop: false);
    }
  }

  Future<void> _pickMes() async {
    final state = ref.read(purchasesListProvider);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var m = 1; m <= 12; m++)
              ListTile(
                dense: true,
                title: Text(_meses[m - 1]),
                trailing: m == state.mes
                    ? const Icon(Icons.check, color: ColorSchema.primaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(purchasesListProvider.notifier)
                      .setMes(m, DateTime.now().year);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasesListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Compras'),
      ),
      floatingActionButton: CustomFloatingActionButton(
        buttonName: 'Registrar',
        onPressed: _nuevaCompra,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar por comprobante…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _pickMes,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(_meses[state.mes - 1].substring(0, 3),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(purchasesListProvider.notifier).refresh(),
              child: state.loading && state.purchases.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.purchases.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                          itemCount:
                              state.purchases.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= state.purchases.length) {
                              return const Padding(
                                padding: EdgeInsets.all(14),
                                child: Center(
                                    child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))),
                              );
                            }
                            return _purchaseCard(state.purchases[i]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 110),
        Icon(Icons.shopping_cart_outlined,
            size: 54, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Center(
            child: Text('No hay compras en este periodo',
                style: TextStyle(color: Colors.grey.shade500))),
        const SizedBox(height: 4),
        Center(
            child: Text('Desliza hacia abajo para actualizar',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
      ],
    );
  }

  String _tipoComprobanteLabel(String? tipo) => switch (tipo) {
        '01' => 'Factura',
        '03' => 'Boleta',
        'NV' => 'N. venta',
        _ => tipo ?? '-',
      };

  Widget _purchaseCard(Purchase compra) {
    final anulado = compra.anulado == true;
    final esCredito = compra.tipoCompra == 'CREDITO';
    final moneda = compra.codigoMoneda == 'USD' ? '\$' : 'S/';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '${compra.comprobante ?? 'Sin número'} · ${_tipoComprobanteLabel(compra.tipoComprobante)}',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    decoration: anulado ? TextDecoration.lineThrough : null,
                    color: anulado ? Colors.grey.shade500 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (anulado)
                _badge('ANULADO', const Color(0xFFFFCDD2), const Color(0xFFC63737))
              else if (esCredito)
                _badge(
                    'CRÉDITO${compra.diasCredito != null ? ' ${compra.diasCredito}d' : ''}',
                    const Color(0xFFFEEDAF),
                    const Color(0xFF8A5340))
              else
                _badge('CONTADO', const Color(0xFFC8E6C9), const Color(0xFF256029)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        compra.proveedor?.razonSocial ??
                            compra.nombreProveedor ??
                            '-',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$moneda ${_fmtMonto.format(compra.totalCompra ?? 0)}',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        decoration: anulado ? TextDecoration.lineThrough : null,
                        color: anulado
                            ? Colors.grey.shade500
                            : ColorSchema.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${compra.fecha != null ? _fmtFecha.format(compra.fecha!) : '-'}'
                  ' · ${compra.items?.length ?? 0} item(s)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          children: [
            ...?compra.items?.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('${_qty(item.cantidad ?? 0)}x',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item.producto?.nombre ?? '-',
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Text(
                        '$moneda ${_fmtMonto.format(item.precioCompra ?? 0)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )),
            if ((compra.motivoAnulacion ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Motivo anulación: ${compra.motivoAnulacion}',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.red.shade400)),
              ),
            ],
            if (!anulado) ...[
              const Divider(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _anular(compra),
                  icon: Icon(Icons.block, size: 16, color: Colors.red.shade400),
                  label: Text('Anular',
                      style: TextStyle(color: Colors.red.shade400)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      );

  String _qty(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
