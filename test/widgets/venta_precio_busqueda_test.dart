import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/search_products.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import '../support/loyalty_fixture.dart';
import '../support/pedidos_fixture.dart';

void main() {
  for (final activo in [false, true]) {
    testWidgets(
      'buscador segrega precios y sigue cabecera, comerciales=$activo',
      (t) async {
        dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
        final sesion = pedidosSession().copyWith(
          comercial: ContextoComercial(
            activo: activo,
            mayoreoManual: true,
            cabecera: 1,
            tipos: [
              {
                'id': 1,
                'categoria': 'POR_DEFECTO',
                'principal': true,
                'estado': true,
              },
              {'id': 2, 'categoria': 'MAYOREO', 'estado': true},
            ],
          ),
        );
        final c = ProviderContainer(
          overrides: [
            sesionProvider.overrideWith((_) => LoyaltySessionNotifier(sesion)),
          ],
        );
        addTearDown(c.dispose);
        final producto = Product(
          nombre: 'Artículo QA',
          moneda: 'PEN',
          preciosVenta: [
            ProductPrice(precio: 100, tipoPrecio: 'POR_DEFECTO'),
            ProductPrice(
              precio: 110,
              tipoPrecio: 'POR_DEFECTO',
              tipoComercialId: 1,
            ),
            ProductPrice(precio: 90, tipoPrecio: 'MAYOREO', tipoComercialId: 2),
          ],
        );
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              home: Scaffold(body: ItemProduct(product: producto)),
            ),
          ),
        );
        expect(find.text(activo ? 'PEN 110.00' : 'PEN 100.00'), findsOneWidget);
        c
            .read(ticketProvider.notifier)
            .updateTicket(
              c.read(ticketProvider).ticket.copyWith(tipoPrecioCabeceraId: 2),
            );
        await t.pump();
        expect(find.text(activo ? 'PEN 90.00' : 'PEN 100.00'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'sin tipo elegible no muestra precio comercial ajeno como tradicional',
    (t) async {
      final p = Product(
        nombre: 'Artículo QA',
        moneda: 'PEN',
        preciosVenta: [
          ProductPrice(
            precio: 110,
            tipoPrecio: 'POR_DEFECTO',
            tipoComercialId: 1,
          ),
        ],
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            sesionProvider.overrideWith(
              (_) => LoyaltySessionNotifier(pedidosSession()),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: ItemProduct(product: p)),
          ),
        ),
      );
      expect(find.text('Sin precio'), findsOneWidget);
      expect(find.text('PEN 110.00'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
