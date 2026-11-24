import 'package:teki_app/src/data/models/page/pageable.dart';
import 'package:teki_app/src/data/models/page/sort.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';

class CustomerResponse {
  final List<Customer> content;
  final bool? empty;
  final bool? first;
  final bool? last;
  final int? number;
  final int? size;
  final int? totalElements;
  final int? totalPages;
  final Sort? sort;
  final Pageable? pageable;

  CustomerResponse({
    required this.content,
    this.empty,
    this.first,
    this.last,
    this.number,
    this.size,
    this.totalElements,
    this.totalPages,
    this.sort,
    this.pageable,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      content: (json['content'] as List<dynamic>?)
              ?.map((x) => Customer.fromJson(x))
              .toList() ??
          [],
      empty: json['empty'],
      first: json['first'],
      last: json['last'],
      number: json['number'],
      size: json['size'],
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
      sort: json['sort'] != null ? Sort.fromJson(json['sort']) : null,
      pageable:
          json['pageable'] != null ? Pageable.fromJson(json['pageable']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content.map((x) => x.toJson()).toList(),
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
