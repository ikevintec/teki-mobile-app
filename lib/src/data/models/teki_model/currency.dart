import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/utils/formats.dart';

class Currency {
  final int? id;
  final String? codigoMoneda;
  final bool? monedaNacional;
  final bool? monedaPorDefecto;
  final double? tipoCambio;
  final Company? empresa;
  final bool? estado;
  final int? createdBy;
  final int? updatedBy;
  final int? deleteBy;
  final DateTime? createdOn;
  final DateTime? updatedOn;
  final DateTime? deletedOn;

  Currency({
    this.id,
    this.codigoMoneda,
    this.monedaNacional,
    this.monedaPorDefecto,
    this.tipoCambio,
    this.empresa,
    this.estado,
    this.updatedBy,
    this.deleteBy,
    this.createdBy,
    this.createdOn,
    this.updatedOn,
    this.deletedOn,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'],
      codigoMoneda: json['codigoMoneda'],
      monedaNacional: json['monedaNacional'],
      monedaPorDefecto: json['monedaPorDefecto'],
      tipoCambio: (json['tipoCambio'] as num?)?.toDouble(),
      empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
      estado: json['estado'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deleteBy: json['deleteBy'],
      createdOn: parseDateTimeFlexible(json['createdOn']),
      updatedOn: parseDateTimeFlexible(json['updatedOn']),
      deletedOn: parseDateTimeFlexible(json['deletedOn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigoMoneda': codigoMoneda,
      'monedaNacional': monedaNacional,
      'monedaPorDefecto': monedaPorDefecto,
      'tipoCambio': tipoCambio,
      'empresa': empresa?.toJson(),
      'estado': estado,
      'createdOn': createdOn?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'updatedOn': updatedOn?.toIso8601String(),
      'deleteBy': deleteBy,
      'deletedOn': deletedOn?.toIso8601String(),
    };
  }

  //metodo copywith
  Currency copyWith({
    int? id,
    String? codigoMoneda,
    bool? monedaNacional,
    bool? monedaPorDefecto,
    double? tipoCambio,
    Company? empresa,
    bool? estado,
    int? createdBy,
    int? updatedBy,
    int? deleteBy,
    DateTime? createdOn,
    DateTime? updatedOn,
    DateTime? deletedOn,
  }) {
    return Currency(
      id: id ?? this.id,
      codigoMoneda: codigoMoneda ?? this.codigoMoneda,
      monedaNacional: monedaNacional ?? this.monedaNacional,
      monedaPorDefecto: monedaPorDefecto ?? this.monedaPorDefecto,
      tipoCambio: tipoCambio ?? this.tipoCambio,
      empresa: empresa ?? this.empresa,
      estado: estado ?? this.estado,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deleteBy: deleteBy ?? this.deleteBy,
      createdOn: createdOn ?? this.createdOn,
      updatedOn: updatedOn ?? this.updatedOn,
      deletedOn: deletedOn ?? this.deletedOn,
    );
  }
}
