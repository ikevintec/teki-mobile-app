import 'package:teki_app/src/data/models/company.dart';

class Customer {
  final int? id;
  final int? idIntegration;
  final String? tipoDocumento;
  final String? numeroDocumento;
  final String? razonSocial;
  final String? genero;
  final String? telefono;
  final String? giro;
  final DateTime? fechaNacimiento;
  final String? referido;
  final String? expediente;
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
  final String? codigoCiudad;
  final String? email;
  final Company? empresa;
  final bool? estado;
  final bool? porDefecto;

  Customer({
    this.id,
    this.idIntegration,
    this.tipoDocumento,
    this.numeroDocumento,
    this.razonSocial,
    this.genero,
    this.telefono,
    this.giro,
    this.fechaNacimiento,
    this.referido,
    this.expediente,
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
    this.codigoCiudad,
    this.email,
    this.empresa,
    this.estado,
    this.porDefecto,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'],
        idIntegration: json['idIntegration'],
        tipoDocumento: json['tipoDocumento'],
        numeroDocumento: json['numeroDocumento'],
        razonSocial: json['razonSocial'],
        genero: json['genero'],
        telefono: json['telefono'],
        giro: json['giro'],
        fechaNacimiento: json['fechaNacimiento'] != null
            ? (json['fechaNacimiento'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['fechaNacimiento'])
                : DateTime.parse(json['fechaNacimiento']))
            : null,
        referido: json['referido'],
        expediente: json['expediente'],
        tipoDireccion: json['tipoDireccion'],
        direccionCompleta: json['direccionCompleta'],
        direccion: json['direccion'],
        numero: json['numero'],
        numeroDepartamento: json['numeroDepartamento'],
        referencia: json['referencia'],
        codigoDepartamento: json['codigoDepartamento'],
        codigoProvincia: json['codigoProvincia'],
        codigoDistrito: json['codigoDistrito'],
        latitud: (json['latitud'] as num?)?.toDouble(),
        longitud: (json['longitud'] as num?)?.toDouble(),
        codigoCiudad: json['codigoCiudad'],
        email: json['email'],
        empresa:
            json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        estado: json['estado'],
        porDefecto: json['porDefecto'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idIntegration': idIntegration,
        'tipoDocumento': tipoDocumento,
        'numeroDocumento': numeroDocumento,
        'razonSocial': razonSocial,
        'genero': genero,
        'telefono': telefono,
        'giro': giro,
        'fechaNacimiento': fechaNacimiento?.toIso8601String(),
        'referido': referido,
        'expediente': expediente,
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
        'codigoCiudad': codigoCiudad,
        'email': email,
        'empresa': empresa?.toJson(),
        'estado': estado,
        'porDefecto': porDefecto,
      };
}
