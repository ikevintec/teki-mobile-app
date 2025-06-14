import 'package:teki_app/src/data/models/teki_model/companySummary.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';

class User {
  final int? id;
  final String? username;
  final String? name;
  final String? cargo;
  final Companysummary? empresa;
  final List<Companysummary>? empresasAdjuntas;
  final List<Office>? puntosVenta;
  final String? avatarUrl;
  final String? rutaInicial;
  final String? rucAsignado;

  User({
    this.id,
    this.username,
    this.name,
    this.cargo,
    this.empresa,
    this.empresasAdjuntas,
    this.puntosVenta,
    this.avatarUrl,
    this.rutaInicial,
    this.rucAsignado,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'],
        name: json['name'],
        cargo: json['cargo'],
        empresa: json['empresa'] != null
            ? Companysummary.fromJson(json['empresa'])
            : null,
        empresasAdjuntas: json['empresasAdjuntas'] != null
            ? List<Companysummary>.from(
                json['empresasAdjuntas'].map((x) => Companysummary.fromJson(x)),
              )
            : [],
        puntosVenta: json['puntosVenta'] != null
            ? List<Office>.from(
                json['puntosVenta'].map((x) => Office.fromJson(x)),
              )
            : [],
        avatarUrl: json['avatarUrl'],
        rutaInicial: json['rutaInicial'],
        rucAsignado: json['rucAsignado'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'cargo': cargo,
        'empresa': empresa?.toJson(),
        'empresasAdjuntas': empresasAdjuntas?.map((e) => e.toJson()).toList(),
        'puntosVenta': puntosVenta?.map((e) => e.toJson()).toList(),
        'avatarUrl': avatarUrl,
        'rutaInicial': rutaInicial,
        'rucAsignado': rucAsignado,
      };
}
