class UnitCode {
  final int? id;
  final String? codigo;
  final String? descripcion;

  UnitCode({
    this.id,
    this.codigo,
    this.descripcion,
  });

  factory UnitCode.fromJson(Map<String, dynamic> json) => UnitCode(
        id: json['id'],
        codigo: json['codigo'],
        descripcion: json['descripcion'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'descripcion': descripcion,
      };
}
