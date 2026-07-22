import 'package:teki_app/src/data/models/teki_model/printer.dart';

class ProductionArea {
  final int? id;
  final String? nombre;
  final List<Printer>? impresoras;

  ProductionArea({
    this.id,
    this.nombre,
    this.impresoras,
  });

  factory ProductionArea.fromJson(Map<String, dynamic> json) => ProductionArea(
        id: json['id'],
        nombre: json['nombre'],
        impresoras: json['impresoras'] != null
            ? List<Printer>.from(
                json['impresoras'].map((x) => Printer.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'impresoras': impresoras?.map((x) => x.toJson()).toList(),
      };
}
