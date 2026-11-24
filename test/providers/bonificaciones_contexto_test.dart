import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/distribuidor/bonificaciones_provider.dart';
import 'package:teki_app/src/providers/sale/products/helpers/ticket_detail_helper.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/pedidos_fixture.dart';
import '../support/loyalty_fixture.dart';

class PromocionesAdapter extends PedidosAdapter {
  bool omitir = false;
  Completer<void>? espera;
  final evaluaciones = <Map<String, dynamic>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    if (o.path == '/distribuidor/promociones/productos-vigentes') {
      return json({
        '1': ['Regalo manual'],
      });
    }
    if (o.path == '/distribuidor/promociones/evaluar') {
      final req = Map<String, dynamic>.from(o.data);
      evaluaciones.add(req);
      await espera?.future;
      if (omitir) {
        return json({
          'aplicadas': [],
          'eleccionesPendientes': [],
          'conflictos': [],
          'bloqueos': [],
          'noAplicadas': [
            {
              'idPromocion': 10,
              'nombre': 'Regalo manual',
              'motivo': 'Se omitió el regalo por falta de stock.',
            },
          ],
        });
      }
      final elegido = (req['selecciones'] as Map)['10'];
      return json({
        'aplicadas': [
          if (elegido != null)
            {
              'idPromocion': 10,
              'nombre': 'Regalo manual',
              'idProductoRegalo': elegido,
              'cantidadRegalo': 1,
            },
        ],
        'eleccionesPendientes': [
          if (elegido == null)
            {
              'idPromocion': 10,
              'nombre': 'Regalo manual',
              'cantidad': 2,
              'opciones': [2, 3],
              'cantidadesPorOpcion': {'2': 2, '3': 1},
            },
        ],
        'noAplicadas': [],
        'conflictos': [],
        'bloqueos': [],
        'regalos': {},
      });
    }
    return super.fetch(o, body, cancel);
  }

  ResponseBody json(Object data) => ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  late PromocionesAdapter api;
  setUp(() {
    dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
    api = PromocionesAdapter();
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = api;
    c = ProviderContainer(
      overrides: [
        sesionProvider.overrideWith(
          (_) => LoyaltySessionNotifier(
            pedidosSession().copyWith(comercial: const ContextoComercial()),
          ),
        ),
      ],
    );
  });
  tearDown(() {
    c.dispose();
    ApiClient.dio.close(force: true);
  });
  Future<void> compra() async {
    final cart = c.read(productSaleProvider.notifier);
    await cart.loadInitialData(null);
    c.read(sesionProvider.notifier).setComercial(const ContextoComercial());
    cart.setProductsSaleEntity([
      getTicketDetail(
        product: Product.fromJson({
          ...PedidosAdapter.product,
          'preciosVenta': [
            {'id': 11, 'tipoPrecio': 'POR_DEFECTO', 'precio': 20.0},
          ],
        }),
        sesion: c.read(sesionProvider),
      ).copyWith(cantidad: 2),
    ]);
  }

  test(
    'OMITIR resuelto permite confirmar sin regalo con comerciales OFF',
    () async {
      api.omitir = true;
      await compra();
      final sub = c.listen(bonificacionesProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(await c.read(bonificacionesProvider.notifier).confirmar(), isTrue);
      expect(c.read(ticketProvider).ticket.totalVenta, closeTo(40, .001));
      expect(
        c.read(bonificacionesProvider).resultado['noAplicadas'],
        hasLength(1),
      );
      expect(
        c
            .read(productSaleProvider)
            .productsSales
            .where((l) => l.esBonificacion == true),
        isEmpty,
      );
      sub.close();
    },
  );

  test(
    'venta nueva exige su elección, conserva regalo y total propios',
    () async {
      await compra();
      final sub = c.listen(bonificacionesProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(
        await c.read(bonificacionesProvider.notifier).confirmar(),
        isFalse,
      );
      c.read(bonificacionesProvider.notifier).elegirRegalo(10, 3);
      expect(await c.read(bonificacionesProvider.notifier).confirmar(), isTrue);
      expect(c.read(ticketProvider).ticket.totalVenta, closeTo(40, .001));
      expect(
        c
            .read(productSaleProvider)
            .productsSales
            .where((l) => l.esBonificacion == true)
            .single
            .cantidad,
        1,
      );
      c.invalidate(ticketProvider);
      c.invalidate(productSaleProvider);
      await compra();
      expect(
        await c.read(bonificacionesProvider.notifier).confirmar(),
        isFalse,
      );
      expect(api.evaluaciones.last['selecciones'], isEmpty);
      expect(
        c
            .read(productSaleProvider)
            .productsSales
            .where((l) => l.esBonificacion == true),
        isEmpty,
      );
      sub.close();
    },
  );

  test(
    'respuesta tardía no agrega regalo ni consulta producto en otra venta',
    () async {
      await compra();
      final sub = c.listen(bonificacionesProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      c.read(bonificacionesProvider.notifier).elegirRegalo(10, 3);
      api.espera = Completer<void>();
      final pendiente = c.read(bonificacionesProvider.notifier).confirmar();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      c.invalidate(ticketProvider);
      c.invalidate(productSaleProvider);
      await compra();
      api.espera!.complete();
      await pendiente;
      expect(
        c
            .read(productSaleProvider)
            .productsSales
            .where((l) => l.esBonificacion == true),
        isEmpty,
      );
      expect(api.requests.where((r) => r.path == '/products/3'), isEmpty);
      expect(c.read(bonificacionesProvider.notifier).selecciones, isEmpty);
      sub.close();
    },
  );
  test(
    'cambio de contexto descarta elecciones y renueva caché de promociones',
    () async {
      await compra();
      final sub = c.listen(bonificacionesProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      final anterior = c.read(comercialPromocionesProvider);
      c.read(bonificacionesProvider.notifier).elegirRegalo(10, 3);
      final session = c.read(sesionProvider);
      // Misma empresa/sede, otro usuario: el contexto no puede reutilizar decisiones.
      final nueva = session.copyWith(login: LoginResponse(user: User(id: 42)));
      (c.read(sesionProvider.notifier) as LoyaltySessionNotifier).replace(
        nueva,
      );
      expect(
        identical(c.read(comercialPromocionesProvider), anterior),
        isFalse,
      );
      expect(c.read(bonificacionesProvider.notifier).selecciones, isEmpty);
      expect(c.read(bonificacionesProvider.notifier).excluyentes, isEmpty);
      sub.close();
    },
  );
  test(
    'resetTicket no recupera decisiones del regalo anterior mientras cambia la canasta',
    () async {
      await compra();
      final sub = c.listen(bonificacionesProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      c.read(bonificacionesProvider.notifier).elegirRegalo(10, 3);
      expect(await c.read(bonificacionesProvider.notifier).confirmar(), isTrue);
      c.read(ticketProvider.notifier).resetTicket();
      await Future<void>.delayed(Duration.zero);
      final cart = c.read(productSaleProvider.notifier);
      cart.setProductsSaleEntity(
        c
            .read(productSaleProvider)
            .productsSales
            .where((l) => l.esBonificacion != true)
            .toList(),
      );
      expect(
        await c.read(bonificacionesProvider.notifier).confirmar(),
        isFalse,
      );
      expect(api.evaluaciones.last['selecciones'], isEmpty);
      expect(c.read(bonificacionesProvider).elecciones, hasLength(1));
      sub.close();
    },
  );
}
