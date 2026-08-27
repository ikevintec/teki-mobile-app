class Companysummary {
  final int? id;
  final String? uuid;
  final String? razonSocial;
  final String? nombreComercial;
  final String? representante;
  final String? telefono;
  final String? email;
  final String? ruc;
  final String? direccion;
  final bool? esProduccion;
  final bool? integracionApi;
  final bool? verNotificacionYape;

  Companysummary({
    this.id,
    this.uuid,
    this.razonSocial,
    this.nombreComercial,
    this.representante,
    this.telefono,
    this.email,
    this.ruc,
    this.direccion,
    this.esProduccion,
    this.integracionApi,
    this.verNotificacionYape,
  });

  factory Companysummary.fromJson(Map<String, dynamic> json) => Companysummary(
        id: json['id'],
        uuid: json['uuid'].toString(),
        razonSocial: json['razonSocial'].toString(),
        nombreComercial: json['nombreComercial'].toString(),
        representante: json['representante'].toString(),
        telefono: json['telefono'].toString(),
        email: json['email'].toString(),
        ruc: json['ruc'].toString(),
        direccion: json['direccion'].toString(),
        esProduccion: json['esProduccion'],
        integracionApi: json['integracionApi'],
        verNotificacionYape: json['verNotificacionYape'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'razonSocial': razonSocial,
        'nombreComercial': nombreComercial,
        'representante': representante,
        'telefono': telefono,
        'email': email,
        'ruc': ruc,
        'direccion': direccion,
        'esProduccion': esProduccion,
        'integracionApi': integracionApi,
        'verNotificacionYape': verNotificacionYape,
      };
}
