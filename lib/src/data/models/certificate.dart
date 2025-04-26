import 'package:teki_app/src/data/models/fileStorage.dart';

class Certificate {
  final int? id;
  final FileStorage? archivo;
  final String? ruc;
  final String? clave;
  final bool? estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  Certificate({
    this.id,
    this.archivo,
    this.ruc,
    this.clave,
    this.estado,
    this.fechaInicio,
    this.fechaFin,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
        id: json['id'],
        archivo: json['archivo'] != null
            ? FileStorage.fromJson(json['archivo'])
            : null,
        ruc: json['ruc'],
        clave: json['clave'],
        estado: json['estado'],
        fechaInicio: json['fechaInicio'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['fechaInicio'] * 1000)
            : null,
        fechaFin: json['fechaFin'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['fechaFin'] * 1000)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'archivo': archivo?.toJson(),
        'ruc': ruc,
        'clave': clave,
        'estado': estado,
        'fechaInicio': fechaInicio != null
            ? (fechaInicio!.millisecondsSinceEpoch ~/ 1000)
            : null,
        'fechaFin': fechaFin != null
            ? (fechaFin!.millisecondsSinceEpoch ~/ 1000)
            : null,
      };
}
