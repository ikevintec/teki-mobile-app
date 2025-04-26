import 'package:teki_app/src/data/models/moduleAccess.dart';

class Permission {
  final int? id;
  final String? nombre;
  final String? codigo;
  final String? ruta;
  final ModuleAccess? modulo;

  Permission({
    this.id,
    this.nombre,
    this.codigo,
    this.ruta,
    this.modulo,
  });

  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
        id: json['id'],
        nombre: json['nombre'],
        codigo: json['codigo'],
        ruta: json['ruta'],
        modulo: json['modulo'] != null
            ? ModuleAccess.fromJson(json['modulo'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'codigo': codigo,
        'ruta': ruta,
        'modulo': modulo?.toJson(),
      };
}
