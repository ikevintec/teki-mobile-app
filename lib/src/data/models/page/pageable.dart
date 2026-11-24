import 'package:teki_app/src/data/models/page/sort.dart';

class Pageable {
  final int? offset;
  final int? pageNumber;
  final int? pageSize;
  final bool? paged;
  final Sort? sort;

  Pageable(
      {
      required this.offset,
      required this.pageNumber,
      required this.pageSize,
      required this.paged,
      required this.sort});

  factory Pageable.fromJson(Map<String, dynamic> json) => Pageable(
        offset: json['offset'],
        pageNumber: json['pageNumber'],
        pageSize: json['pageSize'],
        paged: json['paged'],
        sort: json['sort'] != null ? Sort.fromJson(json['sort']) : null,
      );
  Map<String, dynamic> toJson() => {
        'offset': offset,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'paged': paged,
        'sort': sort?.toJson(),
      };
}
