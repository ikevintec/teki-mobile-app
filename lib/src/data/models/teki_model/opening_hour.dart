import 'package:teki_app/src/data/models/teki_model/opening_hour_detail.dart';

class Openinghour {
  final int? id;
  final String? nombre;
  final List<Openighourdetail>? items;

  Openinghour({
    this.id,
    this.nombre,
    this.items,
  });

  factory Openinghour.fromJson(Map<String, dynamic> json) => Openinghour(
        id: json['id'],
        nombre: json['nombre'],
        items: List<Openighourdetail>.from(
          json['items'].map((x) => Openighourdetail.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'items': items?.map((e) => e.toJson()).toList(),
      };
}
