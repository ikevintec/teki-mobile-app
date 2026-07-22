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

  const ProductSearchEntry({
    required this.position,
    required this.nombre,
    required this.codigo,
    required this.codigoBarra,
  });
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
    ),
    growable: false,
  );
}

/// Devuelve las posiciones de los productos que coinciden con [query].
///
/// Igual que la búsqueda interna de la web, Fuse no es el primer criterio:
/// primero van las coincidencias directas (`includes` en nombre, código o
/// código de barras, en el orden original) y después las difusas. Los grupos no
/// se mezclan.
List<int> runProductSearch(
  List<ProductSearchEntry> index,
  String query, {
  int limit = kLocalSearchMaxResults,
}) {
  final term = query.trim().toLowerCase();
  if (term.isEmpty || index.isEmpty || limit <= 0) return const [];

  final direct = <int>[];
  final matched = <int>{};

  for (final entry in index) {
    if (entry.nombre.contains(term) ||
        entry.codigo.contains(term) ||
        entry.codigoBarra.contains(term)) {
      direct.add(entry.position);
      matched.add(entry.position);
      // Lo difuso iría después del corte igual: nos ahorramos el scan completo.
      if (direct.length >= limit) return direct;
    }
  }

  final rest = [
    for (final entry in index)
      if (!matched.contains(entry.position)) entry,
  ];

  final fuzzy = _fuzzyMatches(rest, term, limit - direct.length);
  if (fuzzy.isEmpty) return direct;
  return [...direct, ...fuzzy];
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
  var scores = const <int, double>{};

  for (final token in tokens) {
    final results =
        Fuzzy<ProductSearchEntry>(candidates, options: _fuzzyOptions)
            .search(token);
    if (results.isEmpty) return const [];

    final nextCandidates = <ProductSearchEntry>[];
    final nextScores = <int, double>{};
    for (final result in results) {
      final position = result.item.position;
      nextScores[position] = (scores[position] ?? 0) + result.score;
      nextCandidates.add(result.item);
    }
    candidates = nextCandidates;
    scores = nextScores;
  }

  final ordered = scores.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return [for (final entry in ordered.take(limit)) entry.key];
}
