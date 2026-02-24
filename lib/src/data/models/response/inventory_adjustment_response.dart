import 'package:teki_app/src/data/models/page/pageable.dart';
import 'package:teki_app/src/data/models/page/sort.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_adjustment.dart';

class InventoryAdjustmentResponse {
  final List<InventoryAdjustment>? content;
  final bool? empty;
  final bool? first;
  final bool? last;
  final int? number;
  final int? size;
  final int? totalElements;
  final int? totalPages;
  final Sort? sort;
  final Pageable? pageable;

  InventoryAdjustmentResponse({
    required this.content,
    required this.empty,
    required this.first,
    required this.last,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.sort,
    required this.pageable,
  });

  factory InventoryAdjustmentResponse.fromJson(Map<String, dynamic> json) =>
      InventoryAdjustmentResponse(
        content: json['content'] != null
            ? List<InventoryAdjustment>.from(
                json['content'].map((x) => InventoryAdjustment.fromJson(x)))
            : [],
        empty: json['empty'],
        first: json['first'] ?? true,
        last: json['last'],
        number: json['number'],
        size: json['size'],
        totalElements: json['totalElements'],
        totalPages: json['totalPages'],
        sort: json['sort'] != null ? Sort.fromJson(json['sort']) : null,
        pageable: json['pageable'] != null
            ? Pageable.fromJson(json['pageable'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'content': content?.map((x) => x.toJson()).toList(),
        'empty': empty,
        'first': first,
        'last': last,
        'number': number,
        'size': size,
        'totalElements': totalElements,
        'totalPages': totalPages,
        'sort': sort?.toJson(),
        'pageable': pageable?.toJson(),
      };
}
