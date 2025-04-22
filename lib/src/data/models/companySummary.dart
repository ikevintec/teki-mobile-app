class Companysummary {
  final int id;
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

  Companysummary({
    required this.id,
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
  });

  factory Companysummary.fromJson(Map<String, dynamic> json) => Companysummary(
        id: json['id'],
        uuid: json['uuid'],
        razonSocial: json['razonSocial'],
        nombreComercial: json['nombreComercial'],
        representante: json['representante'],
        telefono: json['telefono'],
        email: json['email'],
        ruc: json['ruc'],
        direccion: json['direccion'],
        esProduccion: json['esProduccion'],
        integracionApi: json['integracionApi'],
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
      };
}
