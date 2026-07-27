import 'package:fuzzy/fuzzy.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';

/// Mismo tope que la búsqueda por endpoint (`buildProductSearchQueryParams`).
const int kLocalSearchMaxResults = 50;

/// Equivalente a la config de Fuse.js de la web (`product.service.ts`):
/// pesos 0.5/0.3/0.2, `threshold: 0.3`, `minMatchCharLength: 1` e
/// `ignoreLocation: false` (que en Fuse son `location: 0` y `distance: 100`).
///
/// `shouldNormalize` va en `false` porque la web solo hace `trim().toLowerCase()`:
/// no elimina tildes. Marca y categoría no se incluyen: el widget de venta de
/// mobile no usa los filtros adicionales.
final FuzzyOptions<ProductSearchEntry> _fuzzyOptions =
    FuzzyOptions<ProductSearchEntry>(
  isCaseSensitive: false,
  threshold: 0.3,
  minMatchCharLength: 1,
  location: 0,
  distance: 100,
  shouldNormalize: false,
  keys: [
    WeightedKey(name: 'nombre', getter: (e) => e.nombre, weight: 0.5),
    WeightedKey(name: 'codigo', getter: (e) => e.codigo, weight: 0.3),
    WeightedKey(name: 'codigoBarra', getter: (e) => e.codigoBarra, weight: 0.2),
  ],
);

final RegExp _whitespace = RegExp(r'\s+');

/// Producto reducido a lo que se busca, ya normalizado. Evita re-normalizar
/// ~20k productos en cada tecleo y permite mandar el índice a un isolate sin
/// copiar el [Product] completo.
class ProductSearchEntry {
  /// Posición del producto en la lista original en memoria.
  final int position;
  final String nombre;
  final String codigo;
  final String codigoBarra;

  /// Criterio de orden dentro de cada grupo (ver [_byCreatedOnDesc]).
  final int createdOn;

  const ProductSearchEntry({
    required this.position,
    required this.nombre,
    required this.codigo,
    required this.codigoBarra,
    this.createdOn = 0,
  });
}

/// Mismo orden que el endpoint (`sortField: createdOn, sortOrder: -1`) y que la
/// búsqueda interna de la web: más reciente primero. La posición desempata para
/// que el resultado sea estable.
int _byCreatedOnDesc(ProductSearchEntry a, ProductSearchEntry b) {
  final byDate = b.createdOn.compareTo(a.createdOn);
  return byDate != 0 ? byDate : a.position.compareTo(b.position);
}

String _normalize(String? value) => (value ?? '').trim().toLowerCase();

List<ProductSearchEntry> buildProductSearchIndex(List<Product> products) {
  return List<ProductSearchEntry>.generate(
    products.length,
    (i) => ProductSearchEntry(
      position: i,
      nombre: _normalize(products[i].nombre),
      codigo: _normalize(products[i].codigo),
      codigoBarra: _normalize(products[i].codigoBarra),
      createdOn: products[i].createdOn ?? 0,
    ),
    growable: false,
  );
}

/// Devuelve las posiciones de los productos que coinciden con [query].
///
/// Igual que la búsqueda interna de la web, Fuse no es el primer criterio:
/// primero van las coincidencias directas (`includes` en nombre, código o
/// código de barras) y después las difusas. Los grupos no se mezclan y cada uno
/// se ordena por [_byCreatedOnDesc].
List<int> runProductSearch(
  List<ProductSearchEntry> index,
  String query, {
  int limit = kLocalSearchMaxResults,
}) {
  final term = query.trim().toLowerCase();
  if (term.isEmpty || index.isEmpty || limit <= 0) return const [];

  final direct = <ProductSearchEntry>[];
  for (final entry in index) {
    if (entry.nombre.contains(term) ||
        entry.codigo.contains(term) ||
        entry.codigoBarra.contains(term)) {
      direct.add(entry);
    }
  }
  direct.sort(_byCreatedOnDesc);

  // El grupo difuso siempre va después del directo, así que si este ya llena el
  // límite el fuzzy quedaría fuera del corte: nos ahorramos ese recorrido.
  if (direct.length >= limit) {
    return [for (final entry in direct.take(limit)) entry.position];
  }

  final matched = {for (final entry in direct) entry.position};
  final rest = [
    for (final entry in index)
      if (!matched.contains(entry.position)) entry,
  ];

  final fuzzy = _fuzzyMatches(rest, term, limit - direct.length);
  return [
    for (final entry in direct) entry.position,
    ...fuzzy,
  ];
}

/// Equivalente a Fuse con `useExtendedSearch: true`: cada token separado por
/// espacios es una condición AND que puede cumplirse en cualquiera de las keys.
/// Cada token busca solo sobre los sobrevivientes del anterior, así el recorrido
/// completo de la lista ocurre una sola vez.
List<int> _fuzzyMatches(
  List<ProductSearchEntry> entries,
  String term,
  int limit,
) {
  if (entries.isEmpty || limit <= 0) return const [];

  final tokens = term.split(_whitespace)..removeWhere((t) => t.isEmpty);
  if (tokens.isEmpty) return const [];

  var candidates = entries;

  for (final token in tokens) {
    final results =
        Fuzzy<ProductSearchEntry>(candidates, options: _fuzzyOptions)
            .search(token);
    if (results.isEmpty) return const [];
    candidates = [for (final result in results) result.item];
  }

  candidates.sort(_byCreatedOnDesc);
  return [for (final entry in candidates.take(limit)) entry.position];
}
