import 'package:teki_app/src/data/models/teki_model/cityCoverage.dart';
import 'package:teki_app/src/data/models/teki_model/openingHour.dart';

class Office {
  final int? id;
  final String? codigo;
  final String? nombre;
  final String? nombreCorto;
  final Openinghour? horario;
  final List<Citycoverage>? ciudadesAtencion;
  final String? telefono;
  final String? tipoDireccion;
  final String? direccionCompleta;
  final String? direccion;
  final String? numero;
  final String? numeroDepartamento;
  final String? referencia;
  final String? codigoDepartamento;
  final String? codigoProvincia;
  final String? codigoDistrito;
  final double? latitud;
  final double? longitud;
  final String? rucAsignado;

  Office({
    this.id,
    this.codigo,
    this.nombre,
    this.nombreCorto,
    this.horario,
    this.ciudadesAtencion,
    this.telefono,
    this.tipoDireccion,
    this.direccionCompleta,
    this.direccion,
    this.numero,
    this.numeroDepartamento,
    this.referencia,
    this.codigoDepartamento,
    this.codigoProvincia,
    this.codigoDistrito,
    this.latitud,
    this.longitud,
    this.rucAsignado,
  });

  factory Office.fromJson(Map<String, dynamic> json) => Office(
        id: json['id'],
        codigo: json['codigo']?.toString(),
        nombre: json['nombre']?.toString(),
        nombreCorto: json['nombreCorto']?.toString(),
        horario: json['horario'] != null
            ? Openinghour.fromJson(json['horario'])
            : null,
        ciudadesAtencion: List<Citycoverage>.from(
          (json['ciudadesAtencion'] ?? []).map((x) => Citycoverage.fromJson(x)),
        ),
        telefono: json['telefono']?.toString(),
        tipoDireccion: json['tipoDireccion']?.toString(),
        direccionCompleta: json['direccionCompleta']?.toString(),
        direccion: json['direccion']?.toString(),
        numero: json['numero']?.toString(),
        numeroDepartamento: json['numeroDepartamento']?.toString(),
        referencia: json['referencia']?.toString(),
        codigoDepartamento: json['codigoDepartamento'],
        codigoProvincia: json['codigoProvincia']?.toString(),
        codigoDistrito: json['codigoDistrito']?.toString(),
        latitud: (json['latitud'] as num?)?.toDouble(),
        longitud: (json['longitud'] as num?)?.toDouble(),
        rucAsignado: json['rucAsignado'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nombre': nombre,
        'nombreCorto': nombreCorto,
        'horario': horario?.toJson(),
        'ciudadesAtencion': ciudadesAtencion?.map((e) => e.toJson()).toList(),
        'telefono': telefono,
        'tipoDireccion': tipoDireccion,
        'direccionCompleta': direccionCompleta,
        'direccion': direccion,
        'numero': numero,
        'numeroDepartamento': numeroDepartamento,
        'referencia': referencia,
        'codigoDepartamento': codigoDepartamento,
        'codigoProvincia': codigoProvincia,
        'codigoDistrito': codigoDistrito,
        'latitud': latitud,
        'longitud': longitud,
        'rucAsignado': rucAsignado,
      };
}
