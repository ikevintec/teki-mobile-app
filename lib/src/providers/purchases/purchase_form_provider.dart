import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/purchase_detail.dart';
import 'package:teki_app/src/data/models/teki_model/supplier.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_fee.dart';
import 'package:teki_app/src/data/repositories/purchases_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/purchases_repository.dart';

const Object _noValue = Object();

/// Línea del formulario de compra.
class PurchaseFormItem {
  final Product product;
  final double cantidad;
  final double precioCompra; // según incIgv: con o sin impuesto

  const PurchaseFormItem({
    required this.product,
    this.cantidad = 1,
    this.precioCompra = 0,
  });

  PurchaseFormItem copyWith({double? cantidad, double? precioCompra}) =>
      PurchaseFormItem(
        product: product,
        cantidad: cantidad ?? this.cantidad,
        precioCompra: precioCompra ?? this.precioCompra,
      );

  double get importe => cantidad * precioCompra;
}

class PurchaseFormState {
  final Supplier? proveedor;
  final String tipoComprobante; // 01 factura / 03 boleta / NV nota de venta
  final String comprobante;
  final DateTime fecha;
  final String tipoCompra; // CONTADO | CREDITO
  final int diasCredito;
  final bool incIgv;
  final PaymentMethod? metodoPago;
  final List<PurchaseFormItem> items;
  final String observacion;
  final bool submitting;

  PurchaseFormState({
    this.proveedor,
    this.tipoComprobante = '01',
    this.comprobante = '',
    required this.fecha,
    this.tipoCompra = 'CONTADO',
    this.diasCredito = 15,
    this.incIgv = true,
    this.metodoPago,
    this.items = const [],
    this.observacion = '',
    this.submitting = false,
  });

  PurchaseFormState copyWith({
    Object? proveedor = _noValue,
    String? tipoComprobante,
    String? comprobante,
    DateTime? fecha,
    String? tipoCompra,
    int? diasCredito,
    bool? incIgv,
    Object? metodoPago = _noValue,
    List<PurchaseFormItem>? items,
    String? observacion,
    bool? submitting,
  }) =>
      PurchaseFormState(
        proveedor:
            proveedor == _noValue ? this.proveedor : proveedor as Supplier?,
        tipoComprobante: tipoComprobante ?? this.tipoComprobante,
        comprobante: comprobante ?? this.comprobante,
        fecha: fecha ?? this.fecha,
        tipoCompra: tipoCompra ?? this.tipoCompra,
        diasCredito: diasCredito ?? this.diasCredito,
        incIgv: incIgv ?? this.incIgv,
        metodoPago: metodoPago == _noValue
            ? this.metodoPago
            : metodoPago as PaymentMethod?,
        items: items ?? this.items,
        observacion: observacion ?? this.observacion,
        submitting: submitting ?? this.submitting,
      );

  /// Total de la compra (los precios ingresados son finales cuando incIgv).
  double totalCompra(double igvRate) => incIgv
      ? items.fold(0.0, (s, it) => s + it.importe)
      : items.fold(0.0, (s, it) => s + it.importe) * (1 + igvRate);

  double baseImponible(double igvRate) =>
      totalCompra(igvRate) / (1 + igvRate);

  double montoIgv(double igvRate) =>
      totalCompra(igvRate) - baseImponible(igvRate);
}

class PurchaseFormNotifier extends StateNotifier<PurchaseFormState> {
  final PurchasesRepository _repo;

  PurchaseFormNotifier(this._repo)
      : super(PurchaseFormState(fecha: DateTime.now()));

  void setProveedor(Supplier? proveedor) =>
      state = state.copyWith(proveedor: proveedor);

  void setTipoComprobante(String tipo) =>
      state = state.copyWith(tipoComprobante: tipo);

  void setComprobante(String value) =>
      state = state.copyWith(comprobante: value);

  void setFecha(DateTime fecha) => state = state.copyWith(fecha: fecha);

  void setTipoCompra(String tipo) => state = state.copyWith(tipoCompra: tipo);

  void setDiasCredito(int dias) => state = state.copyWith(diasCredito: dias);

  void setIncIgv(bool value) => state = state.copyWith(incIgv: value);

  void setMetodoPago(PaymentMethod? metodo) =>
      state = state.copyWith(metodoPago: metodo);

  void setObservacion(String value) =>
      state = state.copyWith(observacion: value);

  bool addProduct(Product product) {
    if (state.items.any((it) => it.product.id == product.id)) return false;
    state = state.copyWith(items: [
      ...state.items,
      PurchaseFormItem(
        product: product,
        // Precarga el último precio de compra del producto.
        precioCompra: product.precioCompra ?? 0,
      ),
    ]);
    return true;
  }

  void setCantidad(int index, double cantidad) {
    final list = [...state.items];
    list[index] = list[index].copyWith(cantidad: cantidad);
    state = state.copyWith(items: list);
  }

  void setPrecio(int index, double precio) {
    final list = [...state.items];
    list[index] = list[index].copyWith(precioCompra: precio);
    state = state.copyWith(items: list);
  }

  void removeAt(int index) {
    final list = [...state.items]..removeAt(index);
    state = state.copyWith(items: list);
  }

  void reset() => state = PurchaseFormState(fecha: DateTime.now());

  /// Registra la compra espejando el formToModel de la web: CONTADO manda
  /// movimientoCaja.pagos; CREDITO manda diasCredito + una cuota única.
  Future<void> submit({
    required int idPuntoVenta,
    required int idEstacionVenta,
    required String codigoMoneda,
    required double igvRate,
  }) async {
    state = state.copyWith(submitting: true);
    try {
      final total = state.totalCompra(igvRate);
      final items = state.items.map((it) {
        final precioConIgv =
            state.incIgv ? it.precioCompra : it.precioCompra * (1 + igvRate);
        return PurchaseDetail(
          producto: Product(
            id: it.product.id,
            nombre: it.product.nombre,
            moneda: codigoMoneda,
            factor: it.product.factor ?? 1,
            precioCompra: precioConIgv,
            precioCompraNeto: precioConIgv / (1 + igvRate),
            precioCompraIncImp: true,
            monedaReferencial: codigoMoneda,
            precioCompraReferencial: precioConIgv,
            // El backend calcula totalCompra filtrando por tipoAfectacion y
            // valida el tipoProducto: sin estos campos el total sale 0 / NPE.
            tipoAfectacion: it.product.tipoAfectacion ?? '10',
            tipoProducto: it.product.tipoProducto,
            preciosVenta: const [],
          ),
          cantidad: it.cantidad,
          factor: it.product.factor ?? 1,
          precioCompra: precioConIgv,
          precioCompraNeto: precioConIgv / (1 + igvRate),
          importeTotal: it.cantidad * precioConIgv,
          lotes: const [],
        );
      }).toList();

      final esContado = state.tipoCompra == 'CONTADO';
      final purchase = Purchase(
        tipoComprobante: state.tipoComprobante,
        comprobante:
            state.comprobante.trim().isEmpty ? null : state.comprobante.trim(),
        fecha: state.fecha,
        fechaEntrega: state.fecha,
        tipoCompra: state.tipoCompra,
        tipoOperacion: 'COMPRA',
        puntoVenta: Office(id: idPuntoVenta),
        estacionVenta: SaleStation(id: idEstacionVenta),
        proveedor: state.proveedor,
        numeroDocumentoProveedor: state.proveedor?.numeroDocumento,
        nombreProveedor: state.proveedor?.razonSocial,
        codigoMoneda: codigoMoneda,
        incIgv: true,
        igv: igvRate,
        diasCredito: esContado ? null : state.diasCredito,
        observacion:
            state.observacion.trim().isEmpty ? null : state.observacion.trim(),
        movimientoCaja: esContado
            ? CashRegisterDetail(pagos: [
                // Paridad con la venta móvil/web: formaPago y nombre vienen
                // del método (la caja y el arqueo agrupan por esos campos).
                PaymentDetail(
                  metodoPago: state.metodoPago,
                  formaPago: state.metodoPago?.formaPago,
                  nombre: state.metodoPago?.nombre,
                  tipoTarjeta: state.metodoPago?.tipoTarjeta,
                  monto: total,
                  montoPagado: total,
                ),
              ])
            : null,
        cuotas: esContado
            ? null
            : [
                TicketFee(
                  numero: 1,
                  fecha: state.fecha.add(Duration(days: state.diasCredito)),
                  monto: total,
                ),
              ],
        items: items,
      );

      await _repo.savePurchase(purchase);
      reset();
    } catch (e) {
      state = state.copyWith(submitting: false);
      rethrow;
    }
  }
}

final purchaseFormProvider = StateNotifierProvider.autoDispose<
        PurchaseFormNotifier, PurchaseFormState>(
    (ref) => PurchaseFormNotifier(PurchasesRepositoryImpl()));
