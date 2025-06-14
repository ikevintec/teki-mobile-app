import 'package:teki_app/src/data/models/teki_model/accountReceivable.dart';
import 'package:teki_app/src/data/models/teki_model/cashRegisterDetail.dart';
import 'package:teki_app/src/data/models/teki_model/ticketFee.dart';

class AccountsReceivableDetail {
  final int? id;
  final bool? estado;
  final TicketFee? cuota;
  final CashRegisterDetail? cashRegisterDetail;
  final AccountsReceivable? accountsReceivable;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  AccountsReceivableDetail({
    this.id,
    this.estado,
    this.cuota,
    this.cashRegisterDetail,
    this.accountsReceivable,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory AccountsReceivableDetail.fromJson(Map<String, dynamic> json) => AccountsReceivableDetail(
        id: json['id'],
        estado: json['estado'],
        cuota: json['cuota'] != null ? TicketFee.fromJson(json['cuota']) : null,
        cashRegisterDetail: json['cashRegisterDetail'] != null
            ? CashRegisterDetail.fromJson(json['cashRegisterDetail'])
            : null,
        accountsReceivable: json['accountsReceivable'] != null
            ? AccountsReceivable.fromJson(json['accountsReceivable'])
            : null,
        createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'estado': estado,
        'cuota': cuota?.toJson(),
        'cashRegisterDetail': cashRegisterDetail?.toJson(),
        'accountsReceivable': accountsReceivable?.toJson(),
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
