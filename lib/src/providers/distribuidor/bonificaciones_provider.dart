import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/data/services/distribuidor/comercial_service.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';

class BonificacionesState {
  final Map<String, dynamic> resultado;
  final bool calculando;
  final bool vigente;
  final String? error;
  const BonificacionesState({
    this.resultado = const {},
    this.calculando = false,
    this.vigente = false,
    this.error,
  });
  List<dynamic> get aplicadas => resultado['aplicadas'] as List? ?? [];
  List<dynamic> get elecciones =>
      resultado['eleccionesPendientes'] as List? ?? [];
  List<dynamic> get conflictos => resultado['conflictos'] as List? ?? [];
  List<dynamic> get bloqueos => resultado['bloqueos'] as List? ?? [];
  bool get puedeEnviar =>
      vigente &&
      !calculando &&
      error == null &&
      elecciones.isEmpty &&
      conflictos.isEmpty &&
      bloqueos.isEmpty;
}

/// Productos con promoción vigente en la sede (para marcarlos al buscar).
/// Si el servidor no lo soporta o falla, no se marca nada.
final productosConPromocionProvider = FutureProvider.autoDispose
    .family<Map<int, List<String>>, int?>((ref, sede) async {
      try {
        return await ComercialService().productosConPromocion(sede);
      } catch (_) {
        return const {};
      }
    });

final bonificacionesProvider =
    StateNotifierProvider.autoDispose<
      BonificacionesNotifier,
      BonificacionesState
    >(crearBonificaciones);

BonificacionesNotifier crearBonificaciones(Ref ref) {
  final notifier = BonificacionesNotifier(ref);
  ref.listen(productSaleProvider, (_, _) => notifier.programar());
  ref.listen(sesionProvider, (_, _) => notifier.programar());
  ref.listen(ticketProvider, (_, _) => notifier.programar());
  ref.listen(customerSaleProvider, (_, _) => notifier.programar());
  ref.onDispose(notifier.cancelar);
  scheduleMicrotask(notifier.programar);
  return notifier;
}

class BonificacionesNotifier extends StateNotifier<BonificacionesState> {
  final Ref ref;
  Timer? _timer;
  int _revision = 0;
  bool _cerrado = false;
  String? _huella;
  bool _seleccionesInicializadas = false;
  final Map<int, int> selecciones = {};
  final Set<int> excluyentes = {};
  final Map<int, Product> _productos = {};
  BonificacionesNotifier(this.ref) : super(const BonificacionesState());
  void cancelar() {
    _cerrado = true;
    _timer?.cancel();
    _revision++;
  }

  Map<String, dynamic> _solicitud() {
    final carrito = ref.read(productSaleProvider);
    final ticket = ref.read(ticketProvider);
    final sede = ref.read(sesionProvider).office?.id;
    if (!_seleccionesInicializadas && carrito.productsSales.isNotEmpty) {
      for (final l in carrito.productsSales.where(
        (l) =>
            l.esBonificacion == true &&
            l.promocionId != null &&
            l.producto?.id != null,
      )) {
        selecciones[l.promocionId!] = l.producto!.id!;
        excluyentes.add(l.promocionId!);
      }
      _seleccionesInicializadas = true;
    }
    return {
      'documento': ticket.isPedido
          ? 'PEDIDO'
          : ticket.isQuotation
          ? 'COTIZACION'
          : 'VENTA',
      'idPuntoVenta': sede,
      'tipoVenta': ticket.ticket.tipoVenta ?? 'CONTADO',
      if (ticket.isEdit && (ticket.isPedido || ticket.isQuotation))
        'idCotizacion': ticket.ticket.id,
      if (ticket.ticket.cotizacion?.id != null)
        'idCotizacion': ticket.ticket.cotizacion!.id,
      'items': carrito.productsSales
          .where((l) => l.esBonificacion != true)
          .map(
            (l) => {
              'ref':
                  l.uuid ??
                  '${l.numeroItem ?? carrito.productsSales.indexOf(l)}',
              'idProducto': l.producto?.id,
              'cantidad': l.cantidad,
              'importe': l.precioTotal ?? 0,
              'categoria': l.tipoComercialCategoria ?? 'POR_DEFECTO',
              'esBonificacion': false,
            },
          )
          .toList(),
      'selecciones': selecciones.map((k, v) => MapEntry('$k', v)),
      'excluyentesElegidas': excluyentes.toList(),
    };
  }

  void programar({bool forzar = false}) {
    if (_cerrado || ref.read(sesionProvider).comercial == null) return;
    if (ref.read(sesionProvider).comercial?.promocionesDisponibles == false) {
      state = const BonificacionesState(vigente: true);
      return;
    }
    final req = _solicitud();
    final huella = jsonEncode(req);
    if (!forzar && huella == _huella) return;
    _huella = huella;
    _timer?.cancel();
    final revision = ++_revision;
    state = BonificacionesState(resultado: state.resultado, calculando: true);
    _timer = Timer(
      const Duration(milliseconds: 280),
      () => _evaluar(req, revision),
    );
  }

  Future<void> _evaluar(Map<String, dynamic> req, int revision) async {
    try {
      final resultado = await ComercialService().evaluar(req);
      final regalos = <TicketDetail>[];
      for (final dynamic a in resultado['aplicadas'] as List? ?? []) {
        final id = (a['idProductoRegalo'] as num).toInt();
        final product =
            _productos[id] ?? await ProductsRepositoryImpl().getProductById(id);
        _productos[id] = product;
        final sede = ref.read(sesionProvider).office?.id;
        final contexto = ref.read(sesionProvider).comercial;
        final precio =
            contexto?.elegir(product, sede, 1)?.precio ??
            product.preciosVenta
                ?.where(
                  (p) =>
                      p.precio != null &&
                      p.precio! > 0 &&
                      p.paraCanje != true &&
                      (p.puntoVenta == null || p.puntoVenta?.id == sede),
                )
                .firstOrNull
                ?.precio;
        if (precio == null || precio <= 0) {
          throw StateError(
            'Falta valor referencial para el regalo ${product.nombre}.',
          );
        }
        regalos.add(
          TicketDetail(
            uuid: const Uuid().v4(),
            producto: product,
            descripcion: product.nombre,
            cantidad: (a['cantidadRegalo'] as num).toDouble(),
            codigoUnidadMedida: product.unidad?.codigo,
            codigoTipoAfectacionIgv: product.tipoAfectacion == '20'
                ? '21'
                : product.tipoAfectacion == '30'
                ? '31'
                : '15',
            precioVentaUnitario: precio,
            valorUnitario: precio,
            montoOriginal: precio,
            valorReferencialUnitario: precio,
            monedaOriginal: ref
                .read(productSaleProvider)
                .currency
                ?.codigoMoneda,
            esBonificacion: true,
            promocionId: (a['idPromocion'] as num).toInt(),
            descuento: 0,
          ),
        );
      }
      if (_cerrado || revision != _revision) return;
      // Una elección de regalo solo vale mientras su promoción siga aplicada;
      // si se quitó el producto, al volver a cumplirse se elige de nuevo.
      final aplicadasIds = (resultado['aplicadas'] as List? ?? [])
          .map((a) => (a['idPromocion'] as num).toInt())
          .toSet();
      selecciones.removeWhere((k, _) => !aplicadasIds.contains(k));
      final originales = ref
          .read(productSaleProvider)
          .productsSales
          .where((l) => l.esBonificacion != true)
          .toList();
      ref.read(productSaleProvider.notifier).reemplazarLineasComerciales([
        ...originales,
        ...regalos,
      ]);
      state = BonificacionesState(resultado: resultado, vigente: true);
    } catch (e) {
      if (!_cerrado && revision == _revision) {
        state = BonificacionesState(
          resultado: state.resultado,
          error: mensajeComercial(e),
        );
      }
    }
  }

  Future<bool> confirmar() async {
    _timer?.cancel();
    if (ref.read(sesionProvider).comercial?.promocionesDisponibles == false) {
      return true;
    }
    final req = _solicitud();
    _huella = jsonEncode(req);
    final revision = ++_revision;
    state = BonificacionesState(resultado: state.resultado, calculando: true);
    await _evaluar(req, revision);
    return state.puedeEnviar;
  }

  void cambiarRegalo(int promo) {
    selecciones.remove(promo);
    programar(forzar: true);
  }

  void elegirRegalo(int promo, int producto) {
    selecciones[promo] = producto;
    programar(forzar: true);
  }

  /// Deshace la elección entre promociones excluyentes para volver a elegir.
  void liberarExcluyente(int promo) {
    excluyentes.remove(promo);
    programar(forzar: true);
  }

  void elegirPromocion(List<dynamic> grupo, int promo) {
    excluyentes.removeAll(grupo.cast<int>());
    excluyentes.add(promo);
    programar(forzar: true);
  }
}

String mensajeComercial(Object error) {
  // Evitar exponer stack traces o payloads del proveedor en la interfaz.
  final texto = error.toString();
  return texto.startsWith('Bad state: ')
      ? texto.substring(11)
      : 'No se pudo actualizar las bonificaciones. Reintenta antes de enviar.';
}
