import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class BeneficiosVentaState {
  final Map<String, dynamic> resultado;
  final Map<int, String> nombres;
  final bool cargando;
  final String? error;
  const BeneficiosVentaState({
    this.resultado = const {},
    this.nombres = const {},
    this.cargando = false,
    this.error,
  });
  bool get pendientes =>
      cargando ||
      error != null ||
      [
        'conflictos',
        'eleccionesPendientes',
        'bloqueos',
      ].any((key) => (resultado[key] as List? ?? []).isNotEmpty);
}

final beneficiosVentaProvider =
    StateNotifierProvider<BeneficiosVentaNotifier, BeneficiosVentaState>((ref) {
      final notifier = BeneficiosVentaNotifier(ref);
      ref.listen(productSaleProvider, (_, next) => notifier.programar());
      ref.listen(ticketProvider, (_, next) => notifier.programar());
      notifier.programar();
      return notifier;
    });

class BeneficiosVentaNotifier extends StateNotifier<BeneficiosVentaState> {
  final Ref ref;
  Timer? _timer;
  int _revision = 0;
  bool _sincronizando = false;
  String? _firma;
  final Map<int, int> _regalos = {};
  final Set<int> _promociones = {};
  BeneficiosVentaNotifier(this.ref) : super(const BeneficiosVentaState());

  void programar() {
    if (_sincronizando ||
        ref.read(sesionProvider).distribuidor['promociones'] != true) {
      return;
    }
    _timer?.cancel();
    _revision++;
    _timer = Timer(const Duration(milliseconds: 400), () => evaluar());
  }

  void elegirRegalo(int promocion, int producto) {
    _regalos[promocion] = producto;
    _firma = null;
    programar();
  }

  void elegirPromocion(int id, List<dynamic> grupo) {
    _promociones.removeWhere(grupo.contains);
    _promociones.add(id);
    _firma = null;
    programar();
  }

  Future<bool> prepararGuardado() async {
    _timer?.cancel();
    return evaluar(forzar: true);
  }

  Future<bool> evaluar({bool forzar = false}) async {
    final sesion = ref.read(sesionProvider);
    if (sesion.distribuidor['promociones'] != true) return true;
    final ticket = ref.read(ticketProvider),
        lineas = ref.read(productSaleProvider).productsSales;
    final items = <Map<String, dynamic>>[];
    final selecciones = <String, dynamic>{
      for (final e in _regalos.entries) '${e.key}': e.value,
    };
    for (var i = 0; i < lineas.length; i++) {
      final l = lineas[i];
      if (l.comercial['esBonificacion'] == true) {
        selecciones.putIfAbsent(
          '${l.comercial['promocionId']}',
          () => l.producto?.id,
        );
      } else if (l.producto?.id != null) {
        items.add({
          'ref': '$i',
          'idProducto': l.producto!.id,
          'cantidad': l.cantidad,
          'importe': l.precioTotal,
          'categoria': l.comercial['tipoComercialCategoria'],
        });
      }
    }
    final solicitud = {
      'documento': ticket.ticket.tipoComprobante == 'PE'
          ? 'PEDIDO'
          : ticket.isQuotation
          ? 'COTIZACION'
          : 'VENTA',
      'idPuntoVenta': sesion.office?.id,
      'tipoVenta': ticket.ticket.tipoVenta,
      'idCotizacion':
          ticket.ticket.cotizacion?.id ??
          (ticket.isQuotation && ticket.isEdit ? ticket.ticket.id : null),
      'items': items,
      'selecciones': selecciones,
      'excluyentesElegidas': {
        ..._promociones,
        ...selecciones.keys.map(int.parse),
      }.toList(),
    };
    final firma = jsonEncode(solicitud);
    if (!forzar && _firma == firma) return !state.pendientes;
    _firma = firma;
    final revision = ++_revision;
    state = BeneficiosVentaState(
      resultado: state.resultado,
      nombres: state.nombres,
      cargando: true,
    );
    try {
      final r = Map<String, dynamic>.from(
        (await ApiClient.dio.post(
          '/distribuidor/promociones/evaluar',
          data: solicitud,
        )).data,
      );
      final productos = <int, Product>{};
      final pendientes = (r['eleccionesPendientes'] as List? ?? []);
      final ids = <int>{
        for (final a in (r['aplicadas'] as List? ?? []))
          a['idProductoRegalo'] as int,
        for (final e in pendientes)
          for (final id in e['opciones']) id as int,
      };
      await Future.wait(
        ids.map(
          (id) async => productos[id] = await ref
              .read(productSaleProvider.notifier)
              .productsRepository
              .getProductById(id),
        ),
      );
      if (!mounted || revision != _revision) return false;
      final nuevas = lineas
          .where((l) => l.comercial['esBonificacion'] != true)
          .toList();
      final notifier = ref.read(productSaleProvider.notifier);
      for (final a in (r['aplicadas'] as List? ?? [])) {
        nuevas.add(
          notifier.prepararRegalo(
            productos[a['idProductoRegalo']]!,
            (a['cantidadRegalo'] as num).toDouble(),
            a['idPromocion'] as int,
          ),
        );
      }
      final actuales = ref.read(productSaleProvider).productsSales;
      bool mismas = nuevas.length == actuales.length;
      if (mismas)
        for (var i = 0; i < nuevas.length; i++) {
          if (nuevas[i].producto?.id != actuales[i].producto?.id ||
              nuevas[i].cantidad != actuales[i].cantidad ||
              nuevas[i].comercial['promocionId'] !=
                  actuales[i].comercial['promocionId']) {
            mismas = false;
            break;
          }
        }
      if (!mismas) {
        _sincronizando = true;
        try {
          notifier.setProductsSaleEntity(nuevas);
          notifier.calculoTotal();
        } finally {
          _sincronizando = false;
        }
      }
      state = BeneficiosVentaState(
        resultado: r,
        nombres: {
          ...state.nombres,
          for (final p in productos.values) p.id!: p.nombre ?? 'Producto',
        },
      );
      return !state.pendientes;
    } catch (_) {
      if (mounted && revision == _revision) {
        _firma = null;
        state = BeneficiosVentaState(
          resultado: state.resultado,
          nombres: state.nombres,
          error: 'No se pudieron revisar los beneficios. Reintenta.',
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
