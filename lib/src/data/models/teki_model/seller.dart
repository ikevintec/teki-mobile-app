class Seller {
  final int? id;
  final String? nombres;
  final String? apellidos;
  final String? nombreCompleto;

  Seller({
    this.id,
    this.nombres,
    this.apellidos,
    this.nombreCompleto,
  });

  factory Seller.fromJson(Map<String, dynamic> json) => Seller(
        id: json['id'],
        nombres: json['nombres'],
        apellidos: json['apellidos'],
        nombreCompleto: json['nombreCompleto'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombres': nombres,
        'apellidos': apellidos,
        'nombreCompleto': nombreCompleto,
      };
}
