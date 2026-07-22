import 'product.dart';

class GroupOption {
  int? id;
  String? nombre;
  Product? producto;
  double? porcion;
  double? precio;
  bool? porDefecto;
  int? orden;
  bool? modificado;
  bool? eliminado;
  DateTime? createdOn;
  int? createdBy;
  int? updatedBy;
  DateTime? updatedOn;
  int? deleteBy;
  DateTime? deletedOn;

  GroupOption({
    this.id,
    this.nombre,
    this.producto,
    this.porcion,
    this.precio,
    this.porDefecto,
    this.orden,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory GroupOption.fromJson(Map<String, dynamic> json) {
    return GroupOption(
      id: json['id'],
      nombre: json['nombre'],
      producto: json['producto'] != null ? Product.fromJson(json['producto']) : null,
      porcion: (json['porcion'] as num?)?.toDouble(),
      precio: (json['precio'] as num?)?.toDouble(),
      porDefecto: json['porDefecto'],
      orden: json['orden'],
      modificado: json['modificado'],
      eliminado: json['eliminado'],
      createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
      deleteBy: json['deleteBy'],
      deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'producto': producto?.toJson(),
      'porcion': porcion,
      'precio': precio,
      'porDefecto': porDefecto,
      'orden': orden,
      'modificado': modificado,
      'eliminado': eliminado,
      'createdOn': createdOn?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'updatedOn': updatedOn?.toIso8601String(),
      'deleteBy': deleteBy,
      'deletedOn': deletedOn?.toIso8601String(),
    };
  }
}
