class Brand {
  final int? id;
  final String? nombre;

  Brand({
    this.id,
    this.nombre,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'],
        nombre: json['nombre'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
      };
}
