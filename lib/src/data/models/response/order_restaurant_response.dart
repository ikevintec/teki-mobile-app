import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';

class OrderRestaurantResponse {
  final List<OrderRestaurant>? content;
  final bool? empty;
  final bool? first;
  final bool? last;
  final int? number;
  final int? size;
  final int? totalElements;
  final int? totalPages;

  OrderRestaurantResponse({
    required this.content,
    required this.empty,
    required this.first,
    required this.last,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory OrderRestaurantResponse.fromJson(Map<String, dynamic> json) {
    return OrderRestaurantResponse(
      content: json['content'] != null
          ? List<OrderRestaurant>.from(
              json['content'].map((x) => OrderRestaurant.fromJson(x)))
          : [],
      empty: json['empty'],
      first: json['first'] ?? true,
      last: json['last'],
      number: json['number'],
      size: json['size'],
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
    );
  }

  static OrderRestaurantResponse emptyResponse() => OrderRestaurantResponse(
        content: [],
        empty: true,
        first: true,
        last: true,
        number: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
      );
}
