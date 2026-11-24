class LoyaltyPage<T> {
  final List<T> items;
  final int total;
  final bool hasMore;
  const LoyaltyPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  factory LoyaltyPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decode,
  ) => LoyaltyPage(
    items: (json['content'] as List<dynamic>)
        .map((item) => decode(item as Map<String, dynamic>))
        .toList(),
    total: (json['totalElements'] as num).toInt(),
    hasMore: json['last'] == false,
  );
}
