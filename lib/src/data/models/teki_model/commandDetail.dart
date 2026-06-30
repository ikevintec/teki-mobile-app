import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailGroupOption.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailPreparationOption.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/utils/formats.dart';

class CommandDetail {
  final int? id;
  final double? cantidad;
  final double? precioVenta;
  final Product? producto;
  final DateTime? fecha;
  final Check? cuenta;
  final List<CommandDetailGroupOption>? grupoProductoOpciones;
  final List<CommandDetailPreparationOption>? preparacionProductoOpciones;
  final String? estadoComandaDetalle;
  final String? nota;
  final bool? paraLlevar;
  final bool? pagado;
  final Command? comanda;
  final bool? eliminado;
  final bool? modificado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;
  final String? motivoAnulacion;

  CommandDetail({
    this.id,
    this.cantidad,
    this.precioVenta,
    this.producto,
    this.fecha,
    this.cuenta,
    this.grupoProductoOpciones,
    this.preparacionProductoOpciones,
    this.estadoComandaDetalle,
    this.nota,
    this.paraLlevar,
    this.pagado,
    this.comanda,
    this.eliminado,
    this.modificado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
    this.motivoAnulacion,
  });

  factory CommandDetail.fromJson(Map<String, dynamic> json) => CommandDetail(
        id: json['id'],
        cantidad: json['cantidad'],
        precioVenta: json['precioVenta'],
        producto: json['producto'] != null ? Product.fromJson(json['producto']) : null,
        fecha: json['fecha'] != null ? parseDateTimeFlexible(json['fecha']) : null,
        cuenta: json['cuenta'] != null ? Check.fromJson(json['cuenta']) : null,
        grupoProductoOpciones: json['grupoProductoOpciones'] != null
            ? List<CommandDetailGroupOption>.from(json['grupoProductoOpciones'].map((x) => CommandDetailGroupOption.fromJson(x)))
            : null,
        preparacionProductoOpciones: json['preparacionProductoOpciones'] != null
            ? List<CommandDetailPreparationOption>.from(json['preparacionProductoOpciones'].map((x) => CommandDetailPreparationOption.fromJson(x)))
            : null,
        estadoComandaDetalle: json['estadoComandaDetalle'],
        nota: json['nota'],
        paraLlevar: json['paraLlevar'],
        pagado: json['pagado'],
        comanda: json['comanda'] != null ? Command.fromJson(json['comanda']) : null,
        eliminado: json['eliminado'],
        modificado: json['modificado'],
        createdOn: json['createdOn'] != null ? parseDateTimeFlexible(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? parseDateTimeFlexible(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? parseDateTimeFlexible(json['deletedOn']) : null,
        motivoAnulacion: json['motivoAnulacion'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cantidad': cantidad,
        'precioVenta': precioVenta,
        'producto': producto?.toJson(),
        'fecha': fecha?.toIso8601String(),
        'cuenta': cuenta?.toJson(),
        'grupoProductoOpciones': grupoProductoOpciones?.map((x) => x.toJson()).toList(),
        'preparacionProductoOpciones': preparacionProductoOpciones?.map((x) => x.toJson()).toList(),
        'estadoComandaDetalle': estadoComandaDetalle,
        'nota': nota,
        'paraLlevar': paraLlevar,
        'pagado': pagado,
        'comanda': comanda?.toJson(),
        'eliminado': eliminado,
        'modificado': modificado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
        'motivoAnulacion': motivoAnulacion,
      };
}
