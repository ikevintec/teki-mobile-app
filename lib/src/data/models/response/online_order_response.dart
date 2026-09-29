import 'package:teki_app/src/data/models/teki_model/online_order.dart';

class OnlineOrderResponse {
  final List<OnlineOrder> content;
  final int number;
  final int totalPages;
  final int totalElements;
  final bool last;
  final bool first;

  const OnlineOrderResponse({
    this.content = const [],
    this.number = 0,
    this.totalPages = 0,
    this.totalElements = 0,
    this.last = true,
    this.first = true,
  });

  factory OnlineOrderResponse.fromJson(Map<String, dynamic> json) =>
      OnlineOrderResponse(
        content: (json['content'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OnlineOrder.fromJson)
            .toList(),
        number: (json['number'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        last: json['last'] as bool? ?? true,
        first: json['first'] as bool? ?? true,
      );
}
