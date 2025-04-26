import 'package:teki_app/src/data/models/groupOption.dart';

class Group {
  int? id;
  String? nombre;
  String? etiqueta;
  bool? requerido;
  int? forzarMinimo;
  int? forzarMaximo;
  bool? permitirCantidad;
  int? orden;
  String? tipo;
  List<GroupOption>? opciones;

  bool? modificado;
  bool? eliminado;
  DateTime? createdOn;
  int? createdBy;
  int? updatedBy;
  DateTime? updatedOn;
  int? deleteBy;
  DateTime? deletedOn;

  Group({
    this.id,
    this.nombre,
    this.etiqueta,
    this.requerido,
    this.forzarMinimo,
    this.forzarMaximo,
    this.permitirCantidad,
    this.orden,
    this.tipo,
    this.opciones,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      nombre: json['nombre'],
      etiqueta: json['etiqueta'],
      requerido: json['requerido'],
      forzarMinimo: json['forzarMinimo'],
      forzarMaximo: json['forzarMaximo'],
      permitirCantidad: json['permitirCantidad'],
      orden: json['orden'],
      tipo: json['tipo'],
      opciones: json['opciones'] != null
          ? List<GroupOption>.from(json['opciones'].map((x) => GroupOption.fromJson(x)))
          : [],
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
      'etiqueta': etiqueta,
      'requerido': requerido,
      'forzarMinimo': forzarMinimo,
      'forzarMaximo': forzarMaximo,
      'permitirCantidad': permitirCantidad,
      'orden': orden,
      'tipo': tipo,
      'opciones': opciones?.map((x) => x.toJson()).toList(),
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
