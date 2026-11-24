import 'package:teki_app/src/data/models/teki_model/office.dart';

class SerieResponse {
  final int id;
  final String numero; // Esta es la "serie" (ej: B001)
  final String tipoDocumento;
  final Office puntoVenta;

  SerieResponse({
    required this.id,
    required this.numero,
    required this.tipoDocumento,
    required this.puntoVenta,
  });

  factory SerieResponse.fromJson(Map<String, dynamic> json) {
    return SerieResponse(
      id: json['id'],
      numero: json['numero'],
      tipoDocumento: json['tipoDocumento'],
      puntoVenta: Office.fromJson(json['puntoVenta']),
    );
  }
}
