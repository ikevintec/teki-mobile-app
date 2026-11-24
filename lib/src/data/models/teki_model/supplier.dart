class Supplier {
  final int? id;
  final String? numeroDocumento;
  final String? razonSocial;
  final String? direccion;
  final String? telefono;
  final String? email;

  Supplier({
    this.id,
    this.numeroDocumento,
    this.razonSocial,
    this.direccion,
    this.telefono,
    this.email,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'],
        numeroDocumento: json['numeroDocumento'],
        razonSocial: json['razonSocial'],
        direccion: json['direccion'],
        telefono: json['telefono'],
        email: json['email'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'numeroDocumento': numeroDocumento,
        'razonSocial': razonSocial,
        'direccion': direccion,
        'telefono': telefono,
        'email': email,
      };
}
