import 'package:teki_app/src/data/models/permission.dart';

class ModuleAccess {
  final int? id;
  final String? nombre;
  final List<Permission>? permisos;
  final bool? superUsuario;

  ModuleAccess({
    this.id,
    this.nombre,
    this.permisos,
    this.superUsuario,
  });

  factory ModuleAccess.fromJson(Map<String, dynamic> json) => ModuleAccess(
        id: json['id'],
        nombre: json['nombre'],
        superUsuario: json['superUsuario'],
        permisos: json['permisos'] != null
            ? List<Permission>.from(
                json['permisos'].map((x) => Permission.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'superUsuario': superUsuario,
        'permisos': permisos?.map((x) => x.toJson()).toList(),
      };
}
