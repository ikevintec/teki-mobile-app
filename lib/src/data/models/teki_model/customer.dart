import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/utils/formats.dart';

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
        fechaNacimiento: parseDateTimeFlexible(json['fechaNacimiento']),
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
        if(id != null) 'id': id,
        if(idIntegration != null) 'idIntegration': idIntegration,
        'tipoDocumento': tipoDocumento,
        'numeroDocumento': numeroDocumento,
        'razonSocial': razonSocial,
        if(genero != null) 'genero': genero,
        'telefono': telefono,
        if(giro != null) 'giro': giro,
        if(fechaNacimiento != null) 'fechaNacimiento': fechaNacimiento?.toIso8601String(),
        if(referido != null)'referido': referido,
        if(expediente != null)'expediente': expediente,
        if(tipoDireccion != null) 'tipoDireccion': tipoDireccion,
        if(direccionCompleta != null) 'direccionCompleta': direccionCompleta,
        'direccion': direccion,
        'numero': numero,
        'numeroDepartamento': numeroDepartamento,
        'referencia': referencia,
        if(codigoDepartamento != null) 'codigoDepartamento': codigoDepartamento,
        if(codigoProvincia != null)'codigoProvincia': codigoProvincia,
        if(codigoDistrito != null)'codigoDistrito': codigoDistrito,
        if(latitud != null)'latitud': latitud,
        if(longitud != null)'longitud': longitud,
        if(codigoCiudad != null)'codigoCiudad': codigoCiudad,
        'email': email,
        if(empresa != null)'empresa': empresa?.toJson(),
        if(estado != null)'estado': estado,
        if(porDefecto != null)'porDefecto': porDefecto,
      };

}
