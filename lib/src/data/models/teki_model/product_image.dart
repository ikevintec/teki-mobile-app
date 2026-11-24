class ProductImage {
  final int? id;
  final String? imagen;
  final int? numeroOrden;
  final bool? porDefecto;
  final bool? eliminado;

  ProductImage({
    this.id,
    this.imagen,
    this.numeroOrden,
    this.porDefecto,
    this.eliminado,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        id: json['id'],
        imagen: json['imagen'],
        numeroOrden: json['numeroOrden'],
        porDefecto: json['porDefecto'],
        eliminado: json['eliminado'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagen': imagen,
        'numeroOrden': numeroOrden,
        'porDefecto': porDefecto,
        'eliminado': eliminado,
      };

  ProductImage copyWith({
    int? id,
    String? imagen,
    int? numeroOrden,
    bool? porDefecto,
    bool? eliminado,
  }) =>
      ProductImage(
        id: id ?? this.id,
        imagen: imagen ?? this.imagen,
        numeroOrden: numeroOrden ?? this.numeroOrden,
        porDefecto: porDefecto ?? this.porDefecto,
        eliminado: eliminado ?? this.eliminado,
      );
}
