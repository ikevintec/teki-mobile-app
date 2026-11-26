import 'package:teki_app/src/presentation/widgets/product_search_result.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/presentation/screens/customer/customer_sections/create_customer_section.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/data/repositories/customer_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/data/services/distribuidor/comercial_service.dart';
import 'package:teki_app/src/data/services/distribuidor/pedidos_service.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/distribuidor/bonificaciones_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'bonificaciones_panel.dart';
import '../../../domain/distribuidor/comprobante_pedido.dart';
import 'precio_linea.dart';
import 'entrada_numerica_pedido.dart';
import 'resumen_pedido.dart';

import 'pedidos_ui.dart';
import 'busqueda_pedido.dart';
import 'exito_pedido.dart';

class PedidoForm extends ConsumerStatefulWidget {
  final Map<String, dynamic>? pedido, borrador;
  const PedidoForm({super.key, this.pedido, this.borrador});
  @override
  ConsumerState<PedidoForm> createState() => _PedidoFormState();
}

class _PedidoFormState extends ConsumerState<PedidoForm> {
  final _observacion = TextEditingController();
  late final String _contexto;
  late final PedidosService _api;
  late String _borradorId;
  int _revisionBorrador = 0;
  bool _cargando = true, _guardando = false, _incierto = false, _sucio = false;

  /// Productos que aún se están agregando (el buscador puede cerrarse antes).
  int _agregando = 0;
  bool _verObservacion = false;

  /// Solo errores de carga: quedan arriba con Reintentar. El resto va en [_avisar].
  String? _error;
  DateTime? _entrega;
  Map<String, dynamic>? _guardado;
  List<Map<String, dynamic>> _frecuentes = [];
  @override
  void initState() {
    super.initState();
    _contexto = servicioPedidos(ref.read(sesionProvider)).contexto;
    _api = PedidosService(
      _contexto,
      sigueEnContexto: () => mounted && _mismaSesion,
    );
    _borradorId = widget.borrador?['id'] as String? ?? const Uuid().v4();
    Future.microtask(_iniciar);
  }

  bool get _mismaSesion =>
      servicioPedidos(ref.read(sesionProvider)).contexto == _contexto;
  Future<void> _iniciar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref.read(productSaleProvider.notifier).loadInitialData(null);
      if (!mounted || !_mismaSesion) return;
      if (ref.read(productSaleProvider).error != null) {
        throw StateError(
          'No se pudo cargar la configuración. Reintenta antes de agregar productos.',
        );
      }
      final s = ref.read(sesionProvider);
      Map<String, dynamic>? datos = widget.pedido;
      if (widget.borrador != null) {
        final raw = widget.borrador!['datos'];
        final saved = raw is String ? jsonDecode(raw) : raw;
        datos = Map<String, dynamic>.from(saved['pedido']);
        _revisionBorrador = (widget.borrador!['revision'] as num).toInt();
        final boni = ref.read(bonificacionesProvider.notifier);
        (saved['selecciones'] as Map? ?? {}).forEach(
          (k, v) => boni.selecciones[int.parse('$k')] = (v as num).toInt(),
        );
        boni.excluyentes.addAll(
          (saved['excluyentes'] as List? ?? []).cast<int>(),
        );
      }
      Ticket? t = datos == null
          ? null
          : widget.borrador != null
          ? Ticket.fromJson(datos)
          : Quotation.fromJson(datos).toTicketForEdit();
      ref.read(ticketProvider.notifier).startPedido(pedido: t);
      if (t != null) {
        ref
            .read(customerSaleProvider.notifier)
            .setCustomerEntity(t.cliente ?? Customer());
        ref
            .read(productSaleProvider.notifier)
            .setProductsSaleEntity(
              t.items ?? [],
              monedaOrigen: t.codigoMoneda,
              conservarPactos: widget.borrador == null,
            );
        ref.read(productSaleProvider.notifier).setIncIgv(t.incIgv ?? true);
        ref
            .read(productSaleProvider.notifier)
            .setCurrency(t.codigoMoneda ?? 'PEN');
        _observacion.text = datos?['observacion'] as String? ?? '';
        _entrega = DateTime.tryParse('${datos?['fechaEntrega'] ?? ''}');
      }
      final series = await TicketSaleRepositoryImpl().getSeriesPorOficina(
        s.office!.id!,
        'PE',
      );
      if (series.isEmpty) {
        throw StateError(
          'Esta sede no tiene serie de pedidos. Solicita que la configuren para poder enviar.',
        );
      }
      if (t?.serie == null) {
        ref.read(ticketProvider.notifier).setSerie(series.first);
      }
      _incierto = await _api.hayPendiente;
    } catch (e) {
      _error = mensajePedido(e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _cliente() async {
    final customer = await buscarEnPedido<Customer>(
      context,
      'Buscar cliente',
      (q) => CustomersRepositoryImpl().searchCustomers(q),
      (c) => c.razonSocial ?? 'Cliente sin nombre',
      subtitulo: _resumenCliente,
      accionExtra: Builder(
        builder: (ctx) => Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Nuevo cliente'),
            onPressed: () async {
              final nuevo = await Navigator.push<Customer>(
                ctx,
                MaterialPageRoute(
                  builder: (_) =>
                      const AddCustomerSection(devolverCliente: true),
                ),
              );
              if (nuevo != null && ctx.mounted) Navigator.pop(ctx, nuevo);
            },
          ),
        ),
      ),
    );
    if (customer == null || !mounted) return;
    ref.read(customerSaleProvider.notifier).setCustomerEntity(customer);
    _sucio = true;
    setState(() => _frecuentes = []);
    try {
      final c = await ComercialService().cargar(
        ref.read(sesionProvider).office!.id!,
        cliente: customer.id,
        config: ref.read(sesionProvider).config?.configuracionDistribuidor,
      );
      if (!mounted || !_mismaSesion) return;
      if (c.activo) {
        ref
            .read(ticketProvider.notifier)
            .updateTicket(
              ref
                  .read(ticketProvider)
                  .ticket
                  .copyWith(tipoPrecioCabeceraId: c.cabecera),
            );
      }
      final response = await _api.dio.get(
        '/ticket-order/gestion/frecuentes',
        queryParameters: {
          'idCliente': customer.id,
          'idPuntoVenta': ref.read(sesionProvider).office!.id!,
        },
      );
      if (mounted && _mismaSesion) {
        setState(
          () => _frecuentes = (response.data as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
      }
    } catch (e) {
      _avisar(mensajePedido(e));
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _repetirCanasta() async {
    if (_guardando || _incierto) return;
    setState(() => _guardando = true);
    try {
      final cliente = ref.read(customerSaleProvider).customer.id;
      final sede = ref.read(sesionProvider).office!.id!;
      final r = await _api.dio.get(
        '/ticket-order/gestion/ultima-canasta',
        queryParameters: {'idCliente': cliente, 'idPuntoVenta': sede},
      );
      final lista = r.data as List;
      if (lista.isEmpty) {
        throw StateError(
          'No hay una canasta anterior para este cliente en esta sede.',
        );
      }
      if (lista.length > 50) {
        throw StateError(
          'La canasta supera 50 productos. Agrégalos desde el catálogo.',
        );
      }
      if (!mounted || !_mismaSesion) return;
      final aceptar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Repetir última canasta'),
          content: Text(
            'Se agregarán ${lista.length} productos con las cantidades anteriores, usando precios y promociones actuales. Revisa el pedido antes de enviarlo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Agregar productos'),
            ),
          ],
        ),
      );
      if (aceptar != true || !mounted || !_mismaSesion) return;
      final ids = lista.map((l) => l['idProducto']).join(',');
      final productos = await _api.dio.get(
        '/products',
        queryParameters: {
          'paginacion': true,
          'pageNumber': 0,
          'perPage': 50,
          'idsProducto': ids,
          'idPuntoVentaOrder': sede,
        },
      );
      final disponibles = (productos.data['content'] as List)
          .map((p) => (p['id'] as num).toInt())
          .toSet();
      if (!lista.every(
        (l) => disponibles.contains((l['idProducto'] as num).toInt()),
      )) {
        throw StateError(
          'Algunos productos ya no están disponibles. Agrégalos desde el catálogo para revisar sus alternativas.',
        );
      }
      // El listado es ligero: no contiene toda la configuración tributaria/precios.
      // Hasta cuatro detalles en paralelo; no modificar el carrito si alguno falla.
      final todos = <Product>[];
      final repository = ProductsRepositoryImpl();
      for (var inicio = 0; inicio < lista.length; inicio += 4) {
        if (!mounted || !_mismaSesion) return;
        todos.addAll(
          await Future.wait(
            lista
                .skip(inicio)
                .take(4)
                .map(
                  (l) => repository.getProductById(
                    (l['idProducto'] as num).toInt(),
                  ),
                ),
          ),
        );
      }
      if (!mounted || !_mismaSesion) return;
      ref.read(productSaleProvider.notifier).agregarCanasta(todos, {
        for (final l in lista)
          (l['idProducto'] as num).toInt(): (l['cantidad'] as num).toDouble(),
      });
      _sucio = true;
    } catch (e) {
      _avisar(mensajePedido(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Map<String, dynamic> _payload() {
    ref.read(ticketProvider.notifier).setTicketsData();
    // Totales sin redondear, igual que la web: la venta copia este pedido tal
    // cual y el XML de SUNAT redondea al final (UtilFormat.format); redondear
    // aquí descuadra cabecera vs líneas con precios de 4+ decimales.
    return ref.read(ticketProvider.notifier).getTicketPayload().toJson()
      ..['isQuotation'] = false
      ..['observacion'] = _observacion.text.trim()
      ..['adelanto'] = 0
      ..['fechaEntrega'] = _entrega?.toIso8601String();
  }

  Future<void> _guardar({bool enviar = false, bool verificar = false}) async {
    if (_guardando || _agregando > 0) return;
    setState(() => _guardando = true);
    try {
      if (!_mismaSesion) {
        throw StateError(
          'La sesión cambió. Vuelve a abrir tus pedidos en la sede correcta.',
        );
      }
      if (verificar) {
        _guardado = await _api.verificarYReintentar();
      } else {
        final payload = _payload();
        final boni = ref.read(bonificacionesProvider);
        if (enviar) {
          if (ref.read(customerSaleProvider).customer.id == null) {
            throw StateError('Selecciona un cliente antes de enviar.');
          }
          final errorReceptor = validarComprobantePedido(payload);
          if (errorReceptor != null) throw StateError(errorReceptor);
          if (!ref
              .read(productSaleProvider)
              .productsSales
              .any((l) => l.esBonificacion != true)) {
            throw StateError('Agrega al menos un producto.');
          }
          if (!boni.puedeEnviar) {
            throw StateError(
              motivoBonificaciones(boni) ??
                  'Revisa las bonificaciones antes de enviar.',
            );
          }
          _guardado = await _api.enviar({
            'clave': const Uuid().v4(),
            'revision': widget.pedido?['revisionPedido'],
            'pedido': payload,
            if (_revisionBorrador > 0) 'borradorId': _borradorId,
          }, id: widget.pedido?['id'] as int?);
        } else {
          if (widget.pedido != null) {
            throw StateError('Un pedido enviado se guarda con Enviar cambios.');
          }
          if (ref.read(customerSaleProvider).customer.id == null &&
              ref.read(productSaleProvider).productsSales.isEmpty) {
            throw StateError(
              'Elige un cliente o agrega productos antes de guardar el borrador.',
            );
          }
          final n = ref.read(bonificacionesProvider.notifier);
          final b = await _api.guardarBorrador(
            _borradorId,
            _revisionBorrador,
            ref.read(sesionProvider).office!.id!,
            {
              'pedido': payload,
              'selecciones': n.selecciones.map((k, v) => MapEntry('$k', v)),
              'excluyentes': n.excluyentes.toList(),
            },
            ref.read(customerSaleProvider).customer.razonSocial ??
                'Pedido sin cliente',
          );
          _revisionBorrador = (b['revision'] as num).toInt();
          _sucio = false;
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'Borrador guardado. Todavía no se envió el pedido.',
                  ),
                ),
              );
          }
        }
      }
      if (_guardado != null) _sucio = false;
    } catch (e) {
      _avisar(mensajePedido(e));
    } finally {
      _incierto = await _api.hayPendiente;
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cantidad(int i, double actual) async {
    final valor = await showDialog<double>(
      context: context,
      builder: (_) => EntradaNumericaPedido(
        titulo: 'Cantidad',
        etiqueta: 'Cantidad mayor a cero',
        accion: 'Aceptar',
        textoInicial: cantidadPedido(actual),
      ),
    );
    if (valor != null && mounted) {
      ref.read(productSaleProvider.notifier).setCantidadProductSale(i, valor);
      _sucio = true;
    }
  }

  Future<void> _precio(int i) async {
    final cambio = await seleccionarPrecioLinea(context, ref, i);
    if (cambio && mounted) _sucio = true;
  }

  static const _tiposDoc = {
    '0': 'Doc',
    '1': 'DNI',
    '4': 'CE',
    '6': 'RUC',
    '7': 'Pasaporte',
    'A': 'CDI',
  };

  String? _resumenCliente(Customer c) => [
    if ((c.numeroDocumento ?? '').isNotEmpty)
      '${_tiposDoc[c.tipoDocumento] ?? 'Doc'} ${c.numeroDocumento}',
    if (!['', '-'].contains((c.direccion ?? '').trim())) c.direccion!.trim(),
  ].join(' · ');

  static const _unidades = {
    'NIU': 'und',
    'ZZ': 'und',
    'EA': 'und',
    'KGM': 'kg',
    'GRM': 'g',
    'LTR': 'L',
    'MTR': 'm',
    'BX': 'caja',
    'PK': 'paq',
    'DZN': 'doc',
  };

  String _unidad(String? codigo) => _unidades[codigo] ?? (codigo ?? '');

  String _dinero(double? v) {
    final moneda = ref.read(productSaleProvider).currency?.codigoMoneda;
    final simbolo = moneda == null || moneda == 'PEN' ? 'S/' : moneda;
    return '$simbolo ${(v ?? 0).toStringAsFixed(2)}';
  }

  /// Mismo criterio de precio y stock que el buscador de ventas.
  (String, String?) _precioStock(Product p) {
    final sesion = ref.read(sesionProvider);
    final sede = sesion.office?.id;
    final base = sesion.comercial ?? const ContextoComercial();
    final comercial = base.conCabecera(
      base.activo
          ? ref.read(ticketProvider).ticket.tipoPrecioCabeceraId ??
                base.cabecera
          : null,
    );
    final precio = comercial.activo
        ? comercial.elegir(p, sede, 1)?.precio
        : comercial
              .precios(p, sede)
              .where((x) => x.tipoPrecio == 'POR_DEFECTO')
              .firstOrNull
              ?.precio;
    final stock = p.inventarios
        ?.firstWhere(
          (inv) => inv.puntoVenta?.id == sede,
          orElse: () => Inventory(),
        )
        .stock;
    return (
      precio == null ? 'Sin precio' : _dinero(precio),
      stock == null ? null : 'Stock ${cantidadPedido(stock)}',
    );
  }

  double _enPedido(Product p) => ref
      .read(productSaleProvider)
      .productsSales
      .where((l) => l.esBonificacion != true && l.producto?.id == p.id)
      .fold(0.0, (a, l) => a + (l.cantidad ?? 0));

  Future<void> _agregarProducto(Product p, {String? aviso}) async {
    setState(() => _agregando++);
    try {
      await ref
          .read(productSaleProvider.notifier)
          .selectProductForSale(
            p,
            solicitarPrecioManual: (_) => ingresarPrecio(context),
          );
    } finally {
      if (mounted) setState(() => _agregando--);
    }
    _sucio = true;
    if (aviso != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$aviso · ${cantidadPedido(_enPedido(p))} en pedido'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _buscarProductos() async {
    final carritoBusqueda = ref.read(productSaleProvider.notifier);
    bool vigente() =>
        mounted &&
        carritoBusqueda.mounted &&
        identical(ref.read(productSaleProvider.notifier), carritoBusqueda);
    await buscarEnPedido<Product>(
      context,
      'Buscar producto',
      ref.read(productSaleProvider.notifier).searchProducts,
      (p) => p.nombre ?? '',
      subtitulo: (p) => p.codigo,
      lateral: _precioStock,
      etiqueta: _promo,
      agregar: (p) async {
        if (vigente()) await _agregarProducto(p);
      },
      enPedido: _enPedido,
      claveResultado: (p) => p.id ?? p,
      // La hoja vive en el Navigator raíz; conservar el carrito aislado del pedido.
      resultado: (p, agregar, operar, ocupado) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: ProductSearchResult(
          product: p,
          precioStock: _precioStock(p),
          promocion: _promo(p),
          subtitulo: p.codigo,
          agregando: ocupado,
          onAdd: agregar,
          onDecrease: () => operar(() async {
            if (vigente()) _disminuirResultado(p);
          }),
          onRemove: () => operar(() async {
            if (vigente()) _quitarResultado(p);
          }),
          onEdit: () => operar(() async {
            if (vigente()) await _editarResultado(p);
          }),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  List<TicketDetail> _lineasResultado(Product p) => ref
      .read(productSaleProvider)
      .productsSales
      .where((l) => l.producto?.id == p.id && l.esBonificacion != true)
      .toList();

  int _indiceResultado(TicketDetail linea) => ref
      .read(productSaleProvider)
      .productsSales
      .indexWhere(
        (l) => linea.uuid != null ? l.uuid == linea.uuid : identical(l, linea),
      );

  void _disminuirResultado(Product p) {
    if (!mounted) return;
    final linea = _lineasResultado(
      p,
    ).where((l) => l.comandaDetalle == null).lastOrNull;
    if (linea == null) return;
    final indice = _indiceResultado(linea);
    if (indice < 0) return;
    final carrito = ref.read(productSaleProvider.notifier);
    if ((linea.cantidad ?? 1) <= 1) {
      carrito.removeProductSale(indice);
    } else {
      carrito.setCantidadProductSale(
        indice,
        linea.cantidad! - 1,
        actualizarSeries: true,
      );
    }
    _sucio = true;
  }

  void _quitarResultado(Product p) {
    if (!mounted) return;
    final carrito = ref.read(productSaleProvider.notifier);
    for (final linea in _lineasResultado(
      p,
    ).where((l) => l.comandaDetalle == null).toList().reversed) {
      final indice = _indiceResultado(linea);
      if (indice >= 0) carrito.removeProductSale(indice);
    }
    _sucio = true;
  }

  Future<void> _editarResultado(Product p) async {
    if (!mounted) return;
    final carrito = ref.read(productSaleProvider.notifier);
    final cambio = await editarCantidadResultado(
      context,
      p,
      _lineasResultado(p),
    );
    if (!mounted ||
        cambio == null ||
        !carrito.mounted ||
        !identical(ref.read(productSaleProvider.notifier), carrito)) {
      return;
    }
    final indice = _indiceResultado(cambio.$1);
    if (indice < 0) return;
    carrito.setCantidadProductSale(indice, cambio.$2, actualizarSeries: true);
    _sucio = true;
  }

  /// Etiqueta de promoción vigente para el buscador (null si no hay).
  String? _promo(Product p) {
    final sede = ref.read(sesionProvider).office?.id;
    final nombres =
        ref.read(productosConPromocionProvider(sede)).value?[p.id] ?? const [];
    if (nombres.isEmpty) return null;
    return '${nombres.first}${nombres.length > 1 ? ' +${nombres.length - 1}' : ''}';
  }

  String _resumenLineas(ProductsSaleState carrito) {
    final lineas = carrito.productsSales.where((l) => l.esBonificacion != true);
    final n = lineas.length;
    final unidades = lineas.fold(0.0, (a, l) => a + (l.cantidad ?? 0));
    final regalos = carrito.productsSales
        .where((l) => l.esBonificacion == true)
        .fold(0.0, (a, l) => a + (l.cantidad ?? 0));
    return n == 0
        ? 'Sin productos'
        : '$n ${n == 1 ? 'producto' : 'productos'} · ${cantidadPedido(unidades)} und'
              '${regalos > 0 ? ' + ${cantidadPedido(regalos)} de regalo' : ''}';
  }

  Widget _comprobante(
    Customer cliente,
    TicketProvider ticket,
    ProductsSaleState carrito,
  ) {
    final sinRuc = cliente.id != null && cliente.tipoDocumento != '6';
    return DropdownButtonFormField<String>(
      initialValue: ticket.ticket.tipoComprobanteDestino,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: 'Comprobante',
        contentPadding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
        errorMaxLines: 3,
        errorText: cliente.id == null
            ? null
            : validarComprobantePedido({
                'tipoComprobanteDestino': ticket.ticket.tipoComprobanteDestino,
                'cliente': cliente.toJson(),
                'codigoMoneda': carrito.currency?.codigoMoneda,
                'totalVenta': ticket.ticket.totalVenta,
              }),
      ),
      isExpanded: true,
      selectedItemBuilder: (_) => const [
        Text('Factura', maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('Boleta', maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('Nota de venta', maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      items: [
        DropdownMenuItem(
          value: '01',
          enabled: !sinRuc,
          child: Text(
            sinRuc ? 'Factura (requiere RUC)' : 'Factura',
            style: sinRuc
                ? TextStyle(color: Theme.of(context).disabledColor)
                : null,
          ),
        ),
        const DropdownMenuItem(value: '03', child: Text('Boleta')),
        const DropdownMenuItem(value: 'NV', child: Text('Nota de venta')),
      ],
      onChanged: _guardando || _incierto
          ? null
          : (v) {
              if (v != null) {
                ref.read(ticketProvider.notifier).setTipoComprobanteDestino(v);
                _sucio = true;
              }
            },
    );
  }

  Widget _linea(int i, TicketDetail l, TicketProvider ticket) {
    final regalo = l.esBonificacion == true;
    final bloqueado = _guardando || _incierto;
    final estilo = Theme.of(context).textTheme;
    final cabecera =
        ticket.ticket.tipoPrecioCabeceraId ??
        ref.read(sesionProvider).comercial?.cabecera;
    final otroTipo = l.tipoComercialId != null && l.tipoComercialId != cabecera;
    final carrito = ref.read(productSaleProvider.notifier);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (regalo)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.card_giftcard, size: 18),
                  ),
                Expanded(
                  child: Text(
                    l.descripcion ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: estilo.titleSmall,
                  ),
                ),
                if (!regalo) ...[
                  const SizedBox(width: 8),
                  Text(_dinero(l.precioTotal), style: estilo.titleSmall),
                  IconButton(
                    tooltip: 'Quitar producto',
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    onPressed: bloqueado
                        ? null
                        : () {
                            carrito.removeProductSale(i);
                            _sucio = true;
                          },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            if (regalo)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${cantidadPedido(l.cantidad)} ${_unidad(l.codigoUnidadMedida)} de regalo',
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: bloqueado ? null : () => _precio(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${_dinero(l.precioVentaUnitario)} c/u'
                          '${otroTipo ? ' · ${l.tipoComercialNombre ?? ''}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: estilo.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Restar una unidad',
                    visualDensity: VisualDensity.compact,
                    onPressed: bloqueado || (l.cantidad ?? 1) <= 1
                        ? null
                        : () {
                            carrito.setCantidadProductSale(i, l.cantidad! - 1);
                            _sucio = true;
                          },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(56, 36),
                    ),
                    onPressed: bloqueado
                        ? null
                        : () => _cantidad(i, l.cantidad ?? 1),
                    child: Text(
                      '${cantidadPedido(l.cantidad)} ${_unidad(l.codigoUnidadMedida)}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sumar una unidad',
                    visualDensity: VisualDensity.compact,
                    onPressed: bloqueado
                        ? null
                        : () {
                            carrito.setCantidadProductSale(
                              i,
                              (l.cantidad ?? 0) + 1,
                            );
                            _sucio = true;
                          },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(productSaleProvider);
    final ticket = ref.watch(ticketProvider);
    final cliente = ref.watch(customerSaleProvider).customer;
    final boni = ref.watch(bonificacionesProvider);
    // Carga en segundo plano las promociones vigentes para el buscador.
    ref.watch(
      productosConPromocionProvider(ref.watch(sesionProvider).office?.id),
    );
    if (_guardado != null) {
      return ExitoPedido(
        numero: '${_guardado!['serie']}-${_guardado!['numero']}',
        cliente: cliente.razonSocial,
        resumen: _resumenLineas(carrito),
        total: _dinero(ticket.ticket.totalVenta),
        edicion: widget.pedido != null,
        onNuevo: () => Navigator.pop(context, 'nuevo'),
        onVolver: () => Navigator.pop(context),
      );
    }
    return PopScope(
      canPop: !_guardando && (!_sucio || _incierto),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _guardando) return;
        final salir = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Salir del pedido?'),
            content: const Text(
              'Guarda un borrador si quieres retomarlo después.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuar pedido'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salir sin guardar'),
              ),
            ],
          ),
        );
        if (salir == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.pedido == null ? 'Nuevo pedido' : 'Editar pedido'),
          // Altura fija: el cálculo de bonificaciones no desplaza las líneas.
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: SizedBox(
              height: 3,
              child: boni.calculando
                  ? const LinearProgressIndicator(
                      minHeight: 3,
                      semanticsLabel: 'Calculando bonificaciones',
                    )
                  : null,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Ver resumen',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: _cargando || _guardando
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (_) => ResumenPedido(
                        cliente: cliente,
                        comprobante: ticket.ticket.tipoComprobanteDestino,
                        moneda: carrito.currency?.codigoMoneda ?? 'PEN',
                        lineas: List.of(carrito.productsSales),
                        total: ticket.ticket.totalVenta ?? 0,
                        observacion: _observacion.text.trim(),
                        entrega: _entrega,
                        bonificacionesPendientes: !boni.puedeEnviar,
                      ),
                    ),
            ),
          ],
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: Text(_error!),
                        trailing: _guardando
                            ? null
                            : TextButton(
                                onPressed: _iniciar,
                                child: const Text('Reintentar'),
                              ),
                      ),
                    ),
                  if (_incierto)
                    Card(
                      child: ListTile(
                        title: const Text(
                          'Hay un envío pendiente de confirmar',
                        ),
                        subtitle: const Text(
                          'Verifica su resultado antes de continuar.',
                        ),
                        trailing: TextButton(
                          onPressed: _guardando
                              ? null
                              : () => _guardar(verificar: true),
                          child: const Text('Verificar'),
                        ),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(
                      cliente.razonSocial ?? 'Seleccionar cliente',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      cliente.id == null
                          ? 'Bodega que estás visitando'
                          : _resumenCliente(cliente) ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _guardando || _incierto ? null : _cliente,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _comprobante(cliente, ticket, carrito),
                      ),
                      if (ref.watch(sesionProvider).comercial?.activo ==
                          true) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: AbsorbPointer(
                            absorbing: _guardando || _incierto,
                            child: SelectorTipoPrecio(
                              etiqueta: 'Precio',
                              alCambiar: (_) {
                                _sucio = true;
                                if (carrito.productsSales.any(
                                  (l) => l.esBonificacion != true,
                                )) {
                                  _avisar(
                                    'Se aplica a los productos que agregues. '
                                    'Los ya agregados conservan su precio.',
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_frecuentes.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Productos habituales del cliente'),
                      subtitle: const Text(
                        'Se agregan con precios y promociones actuales.',
                      ),
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final p in _frecuentes)
                              ActionChip(
                                label: Text('${p['nombre']}'),
                                onPressed: _guardando || _incierto
                                    ? null
                                    : () => _agregarProducto(
                                        Product(id: p['idProducto'] as int),
                                        aviso: '${p['nombre']}',
                                      ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  AbsorbPointer(
                    absorbing: _guardando || _incierto,
                    child: const BonificacionesPanel(
                      mostrarSelector: false,
                      mostrarCalculando: false,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.search),
                          label: const Text('Agregar productos'),
                          onPressed:
                              _guardando || _incierto || carrito.error != null
                              ? null
                              : _buscarProductos,
                        ),
                      ),
                      if (cliente.id != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _guardando || _incierto
                              ? null
                              : _repetirCanasta,
                          icon: const Icon(Icons.history),
                          label: const Text('Repetir'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < carrito.productsSales.length; i++)
                    _linea(i, carrito.productsSales[i], ticket),
                  const SizedBox(height: 8),
                  if (_verObservacion || _observacion.text.isNotEmpty)
                    TextField(
                      controller: _observacion,
                      enabled: !_guardando && !_incierto,
                      autofocus: _observacion.text.isEmpty,
                      minLines: 1,
                      maxLines: 3,
                      onChanged: (_) => _sucio = true,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones para atención',
                        hintText:
                            'Referencia de entrega o indicación del cliente',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.notes_outlined),
                      title: const Text('Agregar observación (opcional)'),
                      onTap: _guardando || _incierto
                          ? null
                          : () => setState(() => _verObservacion = true),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      _entrega == null
                          ? 'Fecha de entrega (opcional)'
                          : 'Entrega: ${_entrega!.day}/${_entrega!.month}/${_entrega!.year}',
                    ),
                    onTap: _guardando || _incierto
                        ? null
                        : () async {
                            final hoy = DateUtils.dateOnly(DateTime.now());
                            final inicial = DateUtils.dateOnly(_entrega ?? hoy);
                            final desde = hoy.subtract(const Duration(days: 1));
                            final hasta = hoy.add(const Duration(days: 365));
                            // Los pedidos guardados pueden tener fechas fuera del rango habitual.
                            final d = await showDatePicker(
                              context: context,
                              firstDate: inicial.isBefore(desde)
                                  ? inicial
                                  : desde,
                              lastDate: inicial.isAfter(hasta)
                                  ? inicial
                                  : hasta,
                              initialDate: inicial,
                            );
                            if (d != null && mounted) {
                              setState(() {
                                _entrega = d;
                                _sucio = true;
                              });
                            }
                          },
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        _resumenLineas(carrito),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      'Total ${_dinero(ticket.ticket.totalVenta)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed:
                      _guardando ||
                          _cargando ||
                          _incierto ||
                          _agregando > 0 ||
                          boni.calculando ||
                          carrito.error != null
                      ? null
                      : () => _guardar(enviar: true),
                  child: Text(
                    _guardando
                        ? 'Guardando…'
                        : _agregando > 0
                        ? 'Agregando productos…'
                        : widget.pedido == null
                        ? 'Enviar pedido'
                        : 'Enviar cambios',
                  ),
                ),
                if (widget.pedido == null)
                  TextButton(
                    onPressed:
                        _guardando || _cargando || _incierto || _agregando > 0
                        ? null
                        : _guardar,
                    child: const Text('Guardar borrador'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
