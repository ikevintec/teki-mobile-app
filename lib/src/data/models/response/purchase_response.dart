import 'package:teki_app/src/data/models/teki_model/purchase.dart';

/// Respuesta paginada de compras (GET /purchases con paginacion=true).
class PurchaseResponse {
  final List<Purchase> content;
  final int number;
  final int totalPages;
  final int totalElements;
  final bool last;

  PurchaseResponse({
    this.content = const [],
    this.number = 0,
    this.totalPages = 0,
    this.totalElements = 0,
    this.last = true,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) =>
      PurchaseResponse(
        content: json['content'] != null
            ? List<Purchase>.from(
                (json['content'] as List).map((x) => Purchase.fromJson(x)))
            : const [],
        number: json['number'] ?? 0,
        totalPages: json['totalPages'] ?? 0,
        totalElements: json['totalElements'] ?? 0,
        last: json['last'] ?? true,
      );
}
