import 'package:teki_app/src/data/models/teki_model/file_storage.dart';
import 'package:teki_app/src/utils/formats.dart';

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
        fechaInicio: parseDateTimeFlexible(json['fechaInicio']),
        fechaFin: parseDateTimeFlexible(json['fechaFin']),
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
