import 'package:teki_app/src/data/models/teki_model/inventory_production.dart';

/// Respuesta paginada de órdenes de producción.
class InventoryProductionResponse {
  final List<InventoryProduction> content;
  final int number;
  final int totalPages;
  final int totalElements;
  final bool last;
  final bool first;

  InventoryProductionResponse({
    this.content = const [],
    this.number = 0,
    this.totalPages = 0,
    this.totalElements = 0,
    this.last = true,
    this.first = true,
  });

  factory InventoryProductionResponse.fromJson(Map<String, dynamic> json) =>
      InventoryProductionResponse(
        content: json['content'] != null
            ? List<InventoryProduction>.from((json['content'] as List)
                .map((x) => InventoryProduction.fromJson(x)))
            : const [],
        number: json['number'] ?? 0,
        totalPages: json['totalPages'] ?? 0,
        totalElements: json['totalElements'] ?? 0,
        last: json['last'] ?? true,
        first: json['first'] ?? true,
      );
}
