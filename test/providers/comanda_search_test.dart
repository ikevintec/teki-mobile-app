import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/product_image.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/local_products_provider.dart';
import 'package:teki_app/src/domain/repositories/company_repository.dart';
import 'package:teki_app/src/providers/restaurant/comanda_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/direct_checkout_fixture.dart';

class MenuProducts extends Fake implements ProductsRepository {
  final requests = <Map<String, dynamic>>[];
  List<Product> menu = [];
  Future<List<Product>> Function(Map<String, dynamic>)? respond;
  @override
  Future<List<Product>> searchProducts(Map<String, dynamic> params) async {
    requests.add(params);
    return respond != null ? respond!(params) : menu;
  }

  @override
  Future<Map<int, List<ProductImage>>> getImagesByProductIds(
    List<int> ids,
  ) async => {};
}

class MenuInventory extends Fake implements InventoryRepository {
  @override
  Future<Map<int, Inventory>> getInventoryByProductIds(
    List<int> ids, {
    int? idPuntoVenta,
  }) async => {};
}

class MenuRestaurant extends Fake implements RestaurantRepository {}

class MenuSession extends CheckoutSession {
  MenuSession({bool local = false}) {
    state.config!.busquedaProductosLocalmente = local;
  }
}

class MenuCompany extends Fake implements CompanyRepository {}

class LocalMenuCache extends LocalProductsNotifier {
  LocalMenuCache(MenuProducts products, List<Product> menu)
    : super(productsRepository: products, companyRepository: MenuCompany()) {
    state = LocalProductsState(allProducts: menu, isLoaded: true);
  }
  @override
  Future<void> ensureCacheLoaded() async {}
}

void main() {
  late ProviderContainer container;
  late ComandaNotifier notifier;
  late MenuProducts products;
  setUp(() {
    dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'));
    products = MenuProducts();
    container = ProviderContainer(
      overrides: [
        sesionProvider.overrideWith((ref) => MenuSession()),
        comandaProvider.overrideWith(
          (ref) => ComandaNotifier(
            ref: ref,
            repository: MenuRestaurant(),
            productsRepository: products,
            inventoryRepository: MenuInventory(),
          ),
        ),
      ],
    );
    notifier = container.read(comandaProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('metadatos de favoritos y ventas sobreviven JSON y enriquecimiento', () {
    final p = Product.fromJson({
      'id': 1,
      'favorito': true,
      'numeroOrdenFavorito': 2,
      'numeroVentas': 15,
    });
    final copy = Product.fromJson(p.copyWith(nombre: 'Bebida').toJson());
    expect(copy.numeroOrdenFavorito, 2);
    expect(copy.numeroVentas, 15);
  });

  test('sin favoritos muestra más vendidos, hasta diez y en orden', () async {
    products.menu = List.generate(
      15,
      (i) => Product(id: i + 1, favorito: false, numeroVentas: i.toDouble()),
    );
    await notifier.init(null);
    expect(
      notifier.filteredProducts.map((p) => p.id),
      List.generate(10, (i) => 15 - i),
    );
    expect(
      products.requests.any((p) => p['favorito'] == true && p['limit'] == 30),
      isTrue,
    );
  });

  test(
    'favoritos respetan orden compartido y no duplican más vendidos',
    () async {
      products.menu = [
        Product(id: 1, favorito: true, numeroOrdenFavorito: 2),
        Product(id: 2, favorito: true, numeroOrdenFavorito: 1),
        Product(id: 3, favorito: false, numeroVentas: 100),
      ];
      await notifier.init(null);
      expect(notifier.filteredProducts.map((p) => p.id), [2, 1, 3]);
    },
  );

  test(
    'escribir busca fuera de Favoritos y conserva el texto consultado',
    () async {
      await notifier.init(null);
      products.menu = [Product(id: 3, favorito: false, nombre: 'Coca cola')];
      notifier.search('cola');
      await notifier.loadProducts(query: 'cola');
      expect(container.read(comandaProvider).selectedCategoria, isNull);
      expect(container.read(comandaProvider).searchQuery, 'cola');
      expect(notifier.filteredProducts.single.id, 3);
      expect(products.requests.last['filterGlobal'], 'cola');
    },
  );

  test(
    'cache local conserva favoritos más allá de los primeros 500 productos',
    () async {
      final menu = List.generate(
        601,
        (i) => Product(
          id: i + 1,
          mostrarEnRestaurante: true,
          favorito: i == 600,
          numeroOrdenFavorito: i == 600 ? 1 : null,
          numeroVentas: i.toDouble(),
        ),
      );
      final local = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith((ref) => MenuSession(local: true)),
          localProductsProvider.overrideWith(
            (ref) => LocalMenuCache(products, menu),
          ),
          comandaProvider.overrideWith(
            (ref) => ComandaNotifier(
              ref: ref,
              repository: MenuRestaurant(),
              productsRepository: products,
              inventoryRepository: MenuInventory(),
            ),
          ),
        ],
      );
      addTearDown(local.dispose);
      final n = local.read(comandaProvider.notifier);
      await n.init(null);
      expect(n.favoriteProducts.single.id, 601);
      expect(n.filteredProducts.first.id, 601);
      expect(n.topSellingProducts.first.id, 600);
      expect(products.requests, isEmpty);
    },
  );

  test('respuesta antigua no reemplaza una búsqueda nueva', () async {
    final old = Completer<List<Product>>();
    products.respond = (p) async => p['filterGlobal'] == 'co'
        ? old.future
        : [Product(id: 2, nombre: 'Pizza')];
    final first = notifier.loadProducts(query: 'co');
    notifier.search('pizza');
    await notifier.loadProducts(query: 'pizza');
    old.complete([Product(id: 1, nombre: 'Coca cola')]);
    await first;
    expect(container.read(comandaProvider).products.single.id, 2);
    expect(container.read(comandaProvider).searchQuery, 'pizza');
  });
}
