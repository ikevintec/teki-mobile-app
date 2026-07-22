import 'package:teki_app/src/data/models/teki_model/production_area.dart';

class Category {
  final int? id;
  final String? codigo;
  final String? nombre;
  final Category? categoriaPadre;
  final List<Category>? categorias;
  final bool? principal;
  final String? imagenUrl;
  final ProductionArea? areaProduccion;

  Category({
    this.id,
    this.codigo,
    this.nombre,
    this.categoriaPadre,
    this.categorias,
    this.principal,
    this.imagenUrl,
    this.areaProduccion,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        codigo: json['codigo'],
        nombre: json['nombre'],
        categoriaPadre: json['categoriaPadre'] != null
            ? Category.fromJson(json['categoriaPadre'])
            : null,
        categorias: json['categorias'] != null
            ? List<Category>.from(
                json['categorias'].map((x) => Category.fromJson(x)))
            : null,
        principal: json['principal'],
        imagenUrl: json['imagenUrl'],
        areaProduccion: json['areaProduccion'] != null
            ? ProductionArea.fromJson(json['areaProduccion'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nombre': nombre,
        'categoriaPadre': categoriaPadre?.toJson(),
        'categorias': categorias?.map((x) => x.toJson()).toList(),
        'principal': principal,
        'imagenUrl': imagenUrl,
        'areaProduccion': areaProduccion?.toJson(),
      };
}
