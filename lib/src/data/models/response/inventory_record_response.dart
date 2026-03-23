import 'package:teki_app/src/data/models/page/pageable.dart';
import 'package:teki_app/src/data/models/page/sort.dart';
import 'package:teki_app/src/data/models/teki_model/inventoryRecord.dart';

class InventoryRecordResponse {
  final List<InventoryRecord>? content;
  final bool? empty;
  final bool? first;
  final bool? last;
  final int? number;
  final int? size;
  final int? totalElements;
  final int? totalPages;
  final Sort? sort;
  final Pageable? pageable;

  InventoryRecordResponse({
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

  factory InventoryRecordResponse.fromJson(Map<String, dynamic> json) =>
      InventoryRecordResponse(
        content: json['content'] != null
            ? List<InventoryRecord>.from(
                json['content'].map((x) => InventoryRecord.fromJson(x)))
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
