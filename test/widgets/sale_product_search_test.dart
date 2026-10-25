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
