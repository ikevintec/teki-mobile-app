class UnitCode {
  final int? id;
  final String? codigo;
  final String? abreviatura;
  final String? descripcion;

  UnitCode({
    this.id,
    this.codigo,
    this.abreviatura,
    this.descripcion,
  });

  factory UnitCode.fromJson(Map<String, dynamic> json) => UnitCode(
        id: json['id'],
        codigo: json['codigo'],
        abreviatura: json['abreviatura'],
        descripcion: json['descripcion'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'abreviatura': abreviatura, 
        'descripcion': descripcion,
      };
}
