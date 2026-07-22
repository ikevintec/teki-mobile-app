import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';

class OrderRestaurantChangeStatusItems {
  final Command? comanda;
  final List<CommandDetail>? items;

  OrderRestaurantChangeStatusItems({
    this.comanda,
    this.items,
  });

  factory OrderRestaurantChangeStatusItems.fromJson(Map<String, dynamic> json) =>
      OrderRestaurantChangeStatusItems(
        comanda: json['comanda'] != null ? Command.fromJson(json['comanda']) : null,
        items: json['items'] != null
            ? List<CommandDetail>.from(json['items'].map((x) => CommandDetail.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'comanda': comanda?.toJson(),
        'items': items?.map((x) => x.toJson()).toList(),
      };
}
