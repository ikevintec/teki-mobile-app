import 'package:teki_app/src/data/models/teki_model/city.dart';

class Citycoverage {
  final int? id;
  final City? ciudad;
  final double? costoEnvio;

  Citycoverage({
    this.id,
    this.ciudad,
    this.costoEnvio,
  });

  factory Citycoverage.fromJson(Map<String, dynamic> json) => Citycoverage(
    id: json['id'],
    ciudad: City.fromJson(json['ciudad']),
    costoEnvio: (json['costoEnvio'] as num).toDouble(),
  );
    Map<String, dynamic> toJson() => {
        'id': id,
        'ciudad': ciudad?.toJson(),
        'costoEnvio': costoEnvio,
      };
}