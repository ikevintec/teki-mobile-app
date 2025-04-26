import 'package:teki_app/src/data/models/bank.dart';
import 'package:teki_app/src/data/models/company.dart';

class BankAccount {
  final int? id;
  final Bank? banco;
  final String? nombre;
  final String? numero;
  final String? cci;
  final String? titular;
  final String? rucAsignado;
  final bool? detraccion;
  final Company? empresa;
  final bool? estado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  BankAccount({
    this.id,
    this.banco,
    this.nombre,
    this.numero,
    this.cci,
    this.titular,
    this.rucAsignado,
    this.detraccion,
    this.empresa,
    this.estado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        id: json['id'],
        banco: json['banco'] != null ? Bank.fromJson(json['banco']) : null,
        nombre: json['nombre'],
        numero: json['numero'],
        cci: json['cci'],
        titular: json['titular'],
        rucAsignado: json['rucAsignado'],
        detraccion: json['detraccion'],
        empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        estado: json['estado'],
        createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'banco': banco?.toJson(),
        'nombre': nombre,
        'numero': numero,
        'cci': cci,
        'titular': titular,
        'rucAsignado': rucAsignado,
        'detraccion': detraccion,
        'empresa': empresa?.toJson(),
        'estado': estado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };

  /// Getter equivalente a `getName()` de Java
  String? get name => nombre ?? banco?.nombre;

  /// Getter equivalente a `getNumber()` de Java
  String? get number => numero;
}
