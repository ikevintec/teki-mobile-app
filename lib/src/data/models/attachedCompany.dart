import 'package:teki_app/src/data/models/certificate.dart';

class AttachedCompany {
  final int? id;
  final String? razonSocial;
  final String? ruc;
  final String? nombreComercial;
  final String? direccion;
  final String? telefono;
  final String? url;
  final String? urlLogo;
  final String? email;
  final String? emailNotificacion;
  final String? urlOse;
  final String? usuarioSol;
  final String? claveSol;
  final String? usuarioSecSol;
  final String? claveSecSol;
  final String? clientIdSunat;
  final String? clientSecretSunat;
  final Certificate? certificado;
  final String? ubigeo;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final String? representante;

  AttachedCompany({
    this.id,
    this.razonSocial,
    this.ruc,
    this.nombreComercial,
    this.direccion,
    this.telefono,
    this.url,
    this.urlLogo,
    this.email,
    this.emailNotificacion,
    this.urlOse,
    this.usuarioSol,
    this.claveSol,
    this.usuarioSecSol,
    this.claveSecSol,
    this.clientIdSunat,
    this.clientSecretSunat,
    this.certificado,
    this.ubigeo,
    this.departamento,
    this.provincia,
    this.distrito,
    this.representante,
  });

  factory AttachedCompany.fromJson(Map<String, dynamic> json) => AttachedCompany(
        id: json['id'],
        razonSocial: json['razonSocial'],
        ruc: json['ruc'],
        nombreComercial: json['nombreComercial'],
        direccion: json['direccion'],
        telefono: json['telefono'],
        url: json['url'],
        urlLogo: json['urlLogo'],
        email: json['email'],
        emailNotificacion: json['emailNotificacion'],
        urlOse: json['urlOse'],
        usuarioSol: json['usuarioSol'],
        claveSol: json['claveSol'],
        usuarioSecSol: json['usuarioSecSol'],
        claveSecSol: json['claveSecSol'],
        clientIdSunat: json['clientIdSunat'],
        clientSecretSunat: json['clientSecretSunat'],
        certificado: json['certificado'] != null
            ? Certificate.fromJson(json['certificado'])
            : null,
        ubigeo: json['ubigeo'],
        departamento: json['departamento'],
        provincia: json['provincia'],
        distrito: json['distrito'],
        representante: json['representante'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'razonSocial': razonSocial,
        'ruc': ruc,
        'nombreComercial': nombreComercial,
        'direccion': direccion,
        'telefono': telefono,
        'url': url,
        'urlLogo': urlLogo,
        'email': email,
        'emailNotificacion': emailNotificacion,
        'urlOse': urlOse,
        'usuarioSol': usuarioSol,
        'claveSol': claveSol,
        'usuarioSecSol': usuarioSecSol,
        'claveSecSol': claveSecSol,
        'clientIdSunat': clientIdSunat,
        'clientSecretSunat': clientSecretSunat,
        'certificado': certificado?.toJson(),
        'ubigeo': ubigeo,
        'departamento': departamento,
        'provincia': provincia,
        'distrito': distrito,
        'representante': representante,
      };
}
