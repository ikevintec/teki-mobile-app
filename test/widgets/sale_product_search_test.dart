import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/domain/repositories/currency_repository.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/search_products.dart';
import '../support/envase_sale_fixture.dart';

class _Products implements ProductsRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Currency implements CurrencyRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Inventory implements InventoryRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Stations implements SaleStationRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends SesionNotifier {
  _Session() : super(saleStationRepository: _Stations()) {
    state = testSesion;
  }
}

class _Search extends ProductsSaleNotifier {
  final requests = <String, Completer<List<Product>>>{};
  _Search()
    : super(
        ref: SaleTestRef(),
        productsRepository: _Products(),
        currencyRepository: _Currency(),
        inventoryRepository: _Inventory(),
      );
  @override
  Future<List<Product>> searchProducts(String? query) {
    final response = Completer<List<Product>>();
    requests[query!] = response;
    return response.future;
  }
}

class _PendingSelections extends _Search {
  _PendingSelections({this.manualSecond = false});
  final bool manualSecond;
  final firstSelection = Completer<void>();
  final selected = <int>[];
  final manualResults = <double?>[];

  @override
  Future<void> selectProductForSale(
    Product product, {
    Future<double?> Function(Product)? solicitarPrecioManual,
  }) async {
    if (product.id == 1) await firstSelection.future;
    if (!mounted) return;
    if (product.id == 2 && manualSecond) {
      manualResults.add(await solicitarPrecioManual!(product));
      return;
    }
    selected.add(product.id!);
  }
}

Future<void> _pumpSearch(WidgetTester tester, _Search search) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productSaleProvider.overrideWith((_) => search),
        sesionProvider.overrideWith((_) => _Session()),
      ],
      child: MaterialApp(
        home: Scaffold(body: SearchProducts(form: FormGroup({}))),
      ),
    ),
  );
  await tester.tap(find.byType(TextField));
  await tester.pump();
}

void main() {
  for (final scenario in ['conservar', 'descartar', 'precio manual']) {
    testWidgets('salir de búsqueda con dos selecciones pendientes: $scenario', (
      tester,
    ) async {
      final discardCart = scenario == 'descartar';
      final manualSecond = scenario == 'precio manual';
      final search = _PendingSelections(manualSecond: manualSecond);
      final container = ProviderContainer(
        overrides: [
          productSaleProvider.overrideWith((_) => search),
          sesionProvider.overrideWith((_) => _Session()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SearchProducts(form: FormGroup({}))),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'producto');
      await tester.pump(const Duration(milliseconds: 801));
      search.requests['producto']!.complete([
        Product(id: 1, nombre: 'Producto uno'),
        Product(id: 2, nombre: 'Producto dos'),
      ]);
      await tester.pump();
      await tester.tap(find.text('Producto uno'));
      await tester.pump();
      await tester.tap(find.text('Producto dos'));
      await tester.pump();
      // Sale la pantalla; el contenedor/carrito sigue vivo, como al volver al menú.
      await tester.pumpWidget(const SizedBox.shrink());
      if (discardCart) {
        container.invalidate(productSaleProvider);
        await tester.pump(const Duration(milliseconds: 1));
      }
      search.firstSelection.complete();
      await tester.pump();
      expect(
        search.selected,
        discardCart
            ? isEmpty
            : manualSecond
            ? [1]
            : [1, 2],
      );
      expect(search.manualResults, manualSecond ? [null] : isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'una búsqueda lenta no sobrescribe la consulta nueva ni reabre una consulta borrada',
    (tester) async {
      final search = _Search();
      await _pumpSearch(tester, search);
      await tester.enterText(find.byType(TextField), 'anterior');
      await tester.pump(const Duration(milliseconds: 801));
      await tester.enterText(find.byType(TextField), 'actual');
      await tester.pump(const Duration(milliseconds: 801));
      search.requests['actual']!.complete([
        Product(nombre: 'Resultado actual'),
      ]);
      await tester.pump();
      search.requests['anterior']!.complete([
        Product(nombre: 'Resultado viejo'),
      ]);
      await tester.pump();
      expect(find.text('Resultado actual'), findsOneWidget);
      expect(find.text('Resultado viejo'), findsNothing);
      await tester.enterText(find.byType(TextField), 'tercera');
      await tester.pump(const Duration(milliseconds: 801));
      await tester.enterText(find.byType(TextField), '');
      search.requests['tercera']!.complete([
        Product(nombre: 'Resultado tardío'),
      ]);
      await tester.pump();
      expect(find.text('Resultado tardío'), findsNothing);
    },
  );
  testWidgets(
    'un error no se presenta como cero coincidencias y ofrece reintento',
    (tester) async {
      final search = _Search();
      await _pumpSearch(tester, search);
      await tester.enterText(find.byType(TextField), 'arroz');
      await tester.pump(const Duration(milliseconds: 801));
      search.requests['arroz']!.completeError(Exception('offline'));
      await tester.pump();
      expect(find.text('No se encontraron resultados.'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump(const Duration(milliseconds: 801));
      search.requests['arroz']!.complete([]);
      await tester.pump();
      expect(find.text('No se encontraron resultados.'), findsOneWidget);
    },
  );
}
