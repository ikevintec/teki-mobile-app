import 'package:teki_app/src/data/models/page/pageable.dart';
import 'package:teki_app/src/data/models/page/sort.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';

class InventoryTransferResponse {
  final List<InventoryTransfer> content;
  final bool first;
  final bool last;
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;
  final Sort? sort;
  final Pageable? pageable;

  const InventoryTransferResponse({
    required this.content,
    required this.first,
    required this.last,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    this.sort,
    this.pageable,
  });

  factory InventoryTransferResponse.fromJson(Map<String, dynamic> json) =>
      InventoryTransferResponse(
        content: (json['content'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(InventoryTransfer.fromJson)
            .toList(),
        first: json['first'] as bool? ?? true,
        last: json['last'] as bool? ?? true,
        number: json['number'] as int? ?? 0,
        size: json['size'] as int? ?? 0,
        totalElements: json['totalElements'] as int? ?? 0,
        totalPages: json['totalPages'] as int? ?? 0,
        sort: json['sort'] is Map<String, dynamic>
            ? Sort.fromJson(json['sort'] as Map<String, dynamic>)
            : null,
        pageable: json['pageable'] is Map<String, dynamic>
            ? Pageable.fromJson(json['pageable'] as Map<String, dynamic>)
            : null,
      );
}
