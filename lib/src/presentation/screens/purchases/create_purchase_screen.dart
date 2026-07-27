import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/supplier.dart';
import 'package:teki_app/src/data/repositories/purchases_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/product/widget/product_picker_sheet.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/barcode_scanner/barcode_scanner_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/products/products.dart';
import 'package:teki_app/src/providers/purchases/purchase_form_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class CreatePurchaseScreen extends ConsumerStatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  ConsumerState<CreatePurchaseScreen> createState() =>
      _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends ConsumerState<CreatePurchaseScreen> {
  static final _fmt = NumberFormat('#,##0.00', 'es_PE');
  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  // ── Proveedor ─────────────────────────────────────────────────────────
  Future<void> _pickProveedor() async {
    final seleccionado = await showModalBottomSheet<Supplier>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _SupplierPickerSheet(),
    );
    if (seleccionado != null) {
      ref.read(purchaseFormProvider.notifier).setProveedor(seleccionado);
    }
  }

  // ── Items ─────────────────────────────────────────────────────────────
  Future<void> _agregarProducto() async {
    final producto = await ProductPickerSheet.show(context,
        titulo: 'Agregar producto a la compra');
    if (producto == null) return;
    final ok = ref.read(purchaseFormProvider.notifier).addProduct(producto);
    if (!ok) {
      warningNotification('${producto.nombre} ya está agregado', fromTop: false);
    }
  }

  Future<void> _escanear() async {
    final code = await BarcodeScannerSheet.show(context);
    if (code == null || code.isEmpty) return;
    // Busca por código de barras y agrega el primer match.
    ref.read(productsProvider.notifier).searchProducts(code);
    // Espera corta a que la búsqueda resuelva.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final results = ref.read(productsProvider).products;
    if (results.isEmpty) {
      warningNotification('Producto no encontrado: $code', fromTop: false);
      return;
    }
    final ok =
        ref.read(purchaseFormProvider.notifier).addProduct(results.first);
    if (!ok) {
      warningNotification('${results.first.nombre} ya está agregado',
          fromTop: false);
    }
  }

  Future<void> _pickFecha() async {
    final form = ref.read(purchaseFormProvider);
    final fecha = await showDatePicker(
      context: context,
      initialDate: form.fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      ref.read(purchaseFormProvider.notifier).setFecha(fecha);
    }
  }

  Future<void> _registrar() async {
    final form = ref.read(purchaseFormProvider);
    final sesion = ref.read(sesionProvider);
    final idPuntoVenta = sesion.office?.id;
    // La estación es obligatoria: el backend la usa para hallar la caja
    // activa del movimiento de la compra.
    final idEstacionVenta = sesion.saleStation?.id;
    final igvRate = sesion.config?.igv ?? 0.18;

    if (idEstacionVenta == null) {
      warningNotification(
          'Selecciona una estación de venta en Ajustes antes de registrar compras',
          fromTop: false);
      return;
    }
    if (form.proveedor == null) {
      warningNotification('Selecciona el proveedor', fromTop: false);
      return;
    }
    if (form.items.isEmpty) {
      warningNotification('Agrega al menos un producto', fromTop: false);
      return;
    }
    if (form.items.any((it) => it.precioCompra <= 0)) {
      warningNotification('Hay items con precio de compra en 0', fromTop: false);
      return;
    }
    if (form.tipoCompra == 'CONTADO' && form.metodoPago == null) {
      warningNotification('Selecciona el método de pago', fromTop: false);
      return;
    }
    if (idPuntoVenta == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar compra'),
        content: Text(
            'Total S/ ${_fmt.format(form.totalCompra(igvRate))} · ${form.items.length} item(s).\nSe ingresará el stock al inventario. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await ref.read(purchaseFormProvider.notifier).submit(
            idPuntoVenta: idPuntoVenta,
            idEstacionVenta: idEstacionVenta,
            codigoMoneda: 'PEN',
            igvRate: igvRate,
          );
      if (mounted) {
        successNotification('Compra registrada · stock ingresado',
            fromTop: false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      errorNotification(e.toString(), fromTop: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(purchaseFormProvider);
    final sesion = ref.watch(sesionProvider);
    final igvRate = sesion.config?.igv ?? 0.18;
    // Métodos de pago de EGRESO (la compra saca dinero de caja).
    final metodos = (sesion.config?.formasPago ?? [])
        .where((m) => m.tipoMovimiento == null || m.tipoMovimiento == 'EGRESO')
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Nueva compra'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _sectionLabel('PROVEEDOR'),
          _proveedorCard(form),
          const SizedBox(height: 14),
          _sectionLabel('COMPROBANTE'),
          _comprobanteCard(form),
          const SizedBox(height: 14),
          _sectionLabel('ITEMS'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _agregarProducto,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Buscar producto'),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _escanear,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (form.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text('Agrega los productos comprados',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
            )
          else
            ...List.generate(form.items.length, _itemCard),
          const SizedBox(height: 14),
          _totalesCard(form, igvRate, metodos),
          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: ElevatedButton.icon(
            onPressed: form.submitting ? null : _registrar,
            icon: form.submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(
                'Registrar compra · S/ ${_fmt.format(form.totalCompra(igvRate))}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text,
            style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.grey.shade500)),
      );

  BoxDecoration get _cardDeco => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      );

  Widget _proveedorCard(PurchaseFormState form) {
    return Container(
      decoration: _cardDeco,
      child: form.proveedor == null
          ? ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('Seleccionar proveedor',
                  style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickProveedor,
            )
          : ListTile(
              leading: const Icon(Icons.store, color: ColorSchema.primaryColor),
              title: Text(form.proveedor!.razonSocial ?? '-',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('RUC ${form.proveedor!.numeroDocumento ?? '-'}',
                  style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => ref
                    .read(purchaseFormProvider.notifier)
                    .setProveedor(null),
              ),
              onTap: _pickProveedor,
            ),
    );
  }

  Widget _comprobanteCard(PurchaseFormState form) {
    final notifier = ref.read(purchaseFormProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: form.tipoComprobante,
                  decoration: _inputDeco('Tipo'),
                  items: const [
                    DropdownMenuItem(value: '01', child: Text('Factura')),
                    DropdownMenuItem(value: '03', child: Text('Boleta')),
                    DropdownMenuItem(value: 'NV', child: Text('N. venta')),
                  ],
                  onChanged: (v) => notifier.setTipoComprobante(v ?? '01'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: form.comprobante,
                  decoration: _inputDeco('Número (F001-123)'),
                  onChanged: notifier.setComprobante,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickFecha,
                  child: InputDecorator(
                    decoration: _inputDeco('Fecha'),
                    child: Text(_fmtFecha.format(form.fecha),
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: form.tipoCompra,
                  decoration: _inputDeco('Pago'),
                  items: const [
                    DropdownMenuItem(value: 'CONTADO', child: Text('Contado')),
                    DropdownMenuItem(value: 'CREDITO', child: Text('Crédito')),
                  ],
                  onChanged: (v) => notifier.setTipoCompra(v ?? 'CONTADO'),
                ),
              ),
            ],
          ),
          if (form.tipoCompra == 'CREDITO') ...[
            const SizedBox(height: 10),
            TextFormField(
              initialValue: '${form.diasCredito}',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDeco('Días de crédito'),
              onChanged: (v) {
                final dias = int.tryParse(v);
                if (dias != null && dias > 0) notifier.setDiasCredito(dias);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemCard(int index) {
    final form = ref.watch(purchaseFormProvider);
    final item = form.items[index];
    final notifier = ref.read(purchaseFormProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.product.nombre ?? '-',
                    style: GoogleFonts.roboto(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: Colors.red.shade400),
                onPressed: () => notifier.removeAt(index),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _qty(item.cantidad),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: _inputDeco('Cantidad'),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      notifier.setCantidad(index, parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.precioCompra > 0
                      ? item.precioCompra.toString()
                      : '',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: _inputDeco('P. compra unit.'),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) notifier.setPrecio(index, parsed);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text('S/ ${_fmt.format(item.importe)}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.roboto(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalesCard(
      PurchaseFormState form, double igvRate, List<dynamic> metodos) {
    final notifier = ref.read(purchaseFormProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Precios incluyen IGV',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ),
              Switch(
                value: form.incIgv,
                activeThumbColor: ColorSchema.primaryColor,
                onChanged: notifier.setIncIgv,
              ),
            ],
          ),
          _totRow('Base imponible', 'S/ ${_fmt.format(form.baseImponible(igvRate))}'),
          _totRow('IGV ${(igvRate * 100).toStringAsFixed(0)}%',
              'S/ ${_fmt.format(form.montoIgv(igvRate))}'),
          const Divider(height: 16),
          _totRow('Total', 'S/ ${_fmt.format(form.totalCompra(igvRate))}',
              bold: true),
          if (form.tipoCompra == 'CONTADO') ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: form.metodoPago?.id,
              decoration: _inputDeco('Método de pago'),
              items: [
                for (final m in metodos)
                  DropdownMenuItem<int>(
                      value: m.id, child: Text(m.nombre ?? '-')),
              ],
              onChanged: (id) {
                final metodo = metodos.where((m) => m.id == id).toList();
                notifier.setMetodoPago(metodo.isEmpty ? null : metodo.first);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _totRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: bold ? 14.5 : 13,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                      color: bold ? Colors.black87 : Colors.grey.shade600)),
            ),
            Text(value,
                style: GoogleFonts.roboto(
                    fontSize: bold ? 15 : 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      );

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  String _qty(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

// ─── Selector de proveedor ────────────────────────────────────────────────

class _SupplierPickerSheet extends StatefulWidget {
  const _SupplierPickerSheet();

  @override
  State<_SupplierPickerSheet> createState() => _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends State<_SupplierPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Supplier> _resultados = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _buscar('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _buscar(v));
  }

  Future<void> _buscar(String query) async {
    setState(() => _loading = true);
    try {
      final res = await PurchasesRepositoryImpl().searchSuppliers(query.trim());
      if (mounted) setState(() => _resultados = res);
    } catch (_) {
      if (mounted) setState(() => _resultados = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Elegir proveedor',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'RUC o razón social…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _resultados.isEmpty
                  ? Center(
                      child: Text(
                          _loading ? 'Buscando…' : 'Sin proveedores',
                          style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.separated(
                      itemCount: _resultados.length,
                      separatorBuilder: (_, i) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, i) {
                        final s = _resultados[i];
                        return ListTile(
                          title: Text(s.razonSocial ?? '-',
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text('RUC ${s.numeroDocumento ?? '-'}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                          onTap: () => Navigator.of(context).pop(s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
