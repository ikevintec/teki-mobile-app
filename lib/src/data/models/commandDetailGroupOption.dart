import 'package:teki_app/src/data/models/commandDetail.dart';
import 'package:teki_app/src/data/models/product.dart';

class CommandDetailGroupOption {
  final int? id;
  final double? cantidad;
  final int? idGrupo;
  final String? nombreGrupo;
  final int? idOpcion;
  final String? nombreOpcion;
  final double? porcion;
  final double? precio;
  final Product? producto;
  final CommandDetail? comandaDetalle;
  final bool? eliminado;

  CommandDetailGroupOption({
    this.id,
    this.cantidad,
    this.idGrupo,
    this.nombreGrupo,
    this.idOpcion,
    this.nombreOpcion,
    this.porcion,
    this.precio,
    this.producto,
    this.comandaDetalle,
    this.eliminado,
  });

  factory CommandDetailGroupOption.fromJson(Map<String, dynamic> json) => CommandDetailGroupOption(
        id: json['id'],
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        idGrupo: json['idGrupo'],
        nombreGrupo: json['nombreGrupo'],
        idOpcion: json['idOpcion'],
        nombreOpcion: json['nombreOpcion'],
        porcion: (json['porcion'] as num?)?.toDouble(),
        precio: (json['precio'] as num?)?.toDouble(),
        producto: json['producto'] != null ? Product.fromJson(json['producto']) : null,
        comandaDetalle: json['comandaDetalle'] != null ? CommandDetail.fromJson(json['comandaDetalle']) : null,
        eliminado: json['eliminado'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cantidad': cantidad,
        'idGrupo': idGrupo,
        'nombreGrupo': nombreGrupo,
        'idOpcion': idOpcion,
        'nombreOpcion': nombreOpcion,
        'porcion': porcion,
        'precio': precio,
        'producto': producto?.toJson(),
        'comandaDetalle': comandaDetalle?.toJson(),
        'eliminado': eliminado,
      };
}
