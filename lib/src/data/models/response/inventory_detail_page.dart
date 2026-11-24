/// Página de lotes o movimientos; omite el resto de metadatos de Spring Page.
class InventoryDetailPage<T> {
  final List<T> items;
  final bool last;

  const InventoryDetailPage({required this.items, required this.last});

  factory InventoryDetailPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    return InventoryDetailPage(
      items: (json['content'] as List)
          .map((item) => parse(Map<String, dynamic>.from(item as Map)))
          .toList(),
      last: json['last'] as bool,
    );
  }
}
