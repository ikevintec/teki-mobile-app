import 'package:teki_app/src/data/models/commandDetail.dart';

class CommandDetailPreparationOption {
  final int? id;
  final int? idPreparacion;
  final String? nombrePreparacion;
  final int? idOpcion;
  final String? nombreOpcion;
  final CommandDetail? comandaDetalle;
  final bool? eliminado;

  CommandDetailPreparationOption({
    this.id,
    this.idPreparacion,
    this.nombrePreparacion,
    this.idOpcion,
    this.nombreOpcion,
    this.comandaDetalle,
    this.eliminado,
  });

  factory CommandDetailPreparationOption.fromJson(Map<String, dynamic> json) => CommandDetailPreparationOption(
        id: json['id'],
        idPreparacion: json['idPreparacion'],
        nombrePreparacion: json['nombrePreparacion'],
        idOpcion: json['idOpcion'],
        nombreOpcion: json['nombreOpcion'],
        comandaDetalle: json['comandaDetalle'] != null
            ? CommandDetail.fromJson(json['comandaDetalle'])
            : null,
        eliminado: json['eliminado'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'idPreparacion': idPreparacion,
        'nombrePreparacion': nombrePreparacion,
        'idOpcion': idOpcion,
        'nombreOpcion': nombreOpcion,
        'comandaDetalle': comandaDetalle?.toJson(),
        'eliminado': eliminado,
      };
}
