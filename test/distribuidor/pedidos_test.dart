import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import '../support/loyalty_fixture.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/data/services/distribuidor/pedidos_service.dart';
import 'package:teki_app/src/providers/sale/products/helpers/ticket_detail_helper.dart';
import '../support/pedidos_fixture.dart';
import '../support/envase_sale_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
  final tipos = [
    {'id': 1, 'categoria': 'POR_DEFECTO', 'principal': true, 'estado': true},
    {'id': 2, 'categoria': 'MAYOREO', 'estado': true},
  ];
  final product = Product(
    id: 1,
    igv: true,
    preciosPorPuntoVenta: false,
    moneda: 'PEN',
    preciosVenta: [
      ProductPrice(id: 1, precio: 20, tipoPrecio: 'POR_DEFECTO'),
      ProductPrice(
        id: 2,
        precio: 12,
        tipoPrecio: 'POR_DEFECTO',
        tipoComercialId: 1,
      ),
      ProductPrice(
        id: 3,
        precio: 10,
        tipoPrecio: 'MAYOREO',
        tipoComercialId: 2,
      ),
      ProductPrice(
        id: 4,
        precio: 11,
        tipoPrecio: 'POR_DEFECTO',
        tipoComercialId: 1,
        puntoVenta: Office(id: 1),
      ),
      ProductPrice(
        id: 5,
        precio: 9,
        tipoPrecio: 'POR_DEFECTO',
        tipoComercialId: 1,
        puntoVenta: Office(id: 2),
      ),
    ],
  );
  test(
    'comercial separa tradicionales, prioriza sede y permite mayorista sin mínimo manualmente',
    () {
      final c = ContextoComercial(activo: true, cabecera: 1, tipos: tipos);
      expect(c.elegir(product, 1, 100)!.precio, 11);
      expect(c.elegir(product, 1, 1, tipo: 2, explicito: true)!.precio, 10);
      expect(c.precios(product, 1).map((p) => p.id), [2, 3, 4]);
      expect(const ContextoComercial().precios(product, 1).map((p) => p.id), [
        1,
      ]);
    },
  );
  test(
    'automático ignora mayorista con mínimo inválido y no altera pacto al variar cantidad',
    () {
      final c = ContextoComercial(activo: true, cabecera: 1, tipos: tipos);
      final s = testSesion.copyWith(comercial: c);
      expect(getTicketDetail(product: product, sesion: s).tipoComercialId, 1);
      final pactado = TicketDetail(
        producto: product,
        cantidad: 2,
        precioVentaUnitario: 7,
        tipoComercialId: 2,
        origenPrecio: 'PACTADO',
      );
      final cambiado = changeQtyTicketDetail(
        ticketDetail: pactado,
        quantity: 30,
        sesion: s,
      );
      expect(cambiado.precioVentaUnitario, 7);
      expect(cambiado.tipoComercialId, 2);
    },
  );
  test(
    'roundtrip conserva atribución, regalo y revisión de origen al convertir',
    () {
      final q = Quotation.fromJson({
        'id': 21,
        'revisionPedido': 5,
        'tipoPrecioCabeceraId': 1,
        'items': [
          {
            'id': 10,
            'producto': {'id': 1},
            'tipoComercialId': 2,
            'productoPrecioId': 3,
            'origenPrecio': 'ACCIONES',
            'precioReferencia': 10,
            'cantidad': 2,
            'precioVentaUnitario': 9,
          },
          {
            'id': 11,
            'producto': {'id': 1},
            'esBonificacion': true,
            'promocionId': 6,
            'cantidad': 1,
            'precioVentaUnitario': 10,
          },
        ],
      });
      final t = q.toTicketForSale();
      expect(t.cotizacion!.revisionPedido, 5);
      final l = TicketDetail.fromJson(
        t.items!.first.copyWith(cantidad: 4).toJson(),
      );
      expect(l.tipoComercialId, 2);
      expect(l.detalleOrigenId, 10);
      expect(l.productoPrecioId, 3);
      expect(l.origenPrecio, 'ACCIONES');
      expect(t.items![1].esBonificacion, true);
      expect(t.items![1].promocionId, 6);
    },
  );
  test(
    'respuesta perdida: verifica mismo pedido sin segundo POST y aísla otra sesión',
    () async {
      SharedPreferences.setMockInitialValues({});
      final adapter = PedidosAdapter()..perderRespuesta = true;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = adapter;
      final api = PedidosService('empresa1-user1-sede1', dio: dio);
      final comando = {
        'clave': 'prueba-pedido-idempotente-01',
        'pedido': {'serie': 'P001'},
      };
      await expectLater(api.enviar(comando), throwsA(isA<DioException>()));
      expect(await api.hayPendiente, true);
      await expectLater(api.enviar(comando), throwsStateError);
      expect(
        await PedidosService('empresa2-user1-sede1', dio: dio).hayPendiente,
        false,
      );
      final recuperado = await api.verificarYReintentar();
      expect(recuperado!['id'], 1);
      expect(adapter.registros, 1);
      expect(await api.hayPendiente, false);
      expect(adapter.requests.where((o) => o.method == 'POST').length, 1);
    },
  );
  test(
    'cabecera solo afecta nuevas líneas, incluso al cambiar cantidad después',
    () {
      final s = testSesion.copyWith(
        comercial: ContextoComercial(
          activo: true,
          mayoreoManual: true,
          cabecera: 1,
          tipos: tipos,
        ),
      );
      final linea = getTicketDetail(product: product, sesion: s);
      final nuevo = s.copyWith(comercial: s.comercial!.conCabecera(2));
      final cambiado = changeQtyTicketDetail(
        ticketDetail: linea,
        quantity: 3,
        sesion: nuevo,
      );
      expect(cambiado.tipoComercialId, 1);
      expect(cambiado.precioVentaUnitario, 11);
      expect(
        getTicketDetail(product: product, sesion: nuevo).tipoComercialId,
        2,
      );
    },
  );
  test(
    'manual autorizado sin precio declarado conserva tipo y moneda para cambios de cantidad',
    () {
      final s = testSesion.copyWith(
        comercial: ContextoComercial(
          activo: true,
          mayoreoManual: true,
          cabecera: 2,
          tipos: tipos,
        ),
      );
      final linea = getTicketDetail(
        product: Product(
          id: 9,
          moneda: 'PEN',
          igv: true,
          tipoAfectacion: '10',
          preciosVenta: [],
        ),
        sesion: s,
        precioManual: 7.5,
      );
      expect(linea.tipoComercialId, 2);
      expect(linea.origenPrecio, 'MANUAL');
      expect(linea.productoPrecioId, isNull);
      expect(
        changeQtyTicketDetail(
          ticketDetail: linea,
          quantity: 10,
          sesion: s,
        ).precioVentaUnitario,
        7.5,
      );
    },
  );
  test(
    'cargar precios conserva el carrito y cambiar de sede crea otro contexto',
    () {
      final session = LoyaltySessionNotifier(pedidosSession());
      final c = ProviderContainer(
        overrides: [sesionProvider.overrideWith((_) => session)],
      );
      addTearDown(c.dispose);
      final carrito = c.read(productSaleProvider.notifier);
      carrito.setFilterGlobal('arroz');
      final ticket = c.read(ticketProvider.notifier);
      ticket.startPedido();
      session.replace(
        c
            .read(sesionProvider)
            .copyWith(comercial: const ContextoComercial(activo: true)),
      );
      expect(identical(c.read(productSaleProvider.notifier), carrito), true);
      expect(c.read(productSaleProvider).filterGlobal, 'arroz');
      expect(c.read(ticketProvider).isPedido, true);
      session.replace(c.read(sesionProvider).copyWith(office: Office(id: 2)));
      expect(identical(c.read(productSaleProvider.notifier), carrito), false);
      expect(c.read(productSaleProvider).filterGlobal, '');
      expect(c.read(ticketProvider).isPedido, false);
    },
  );
}
