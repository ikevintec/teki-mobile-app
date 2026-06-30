import 'package:teki_app/src/data/models/teki_model/accountReceivableDetail.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/saleStation.dart';
import 'package:teki_app/src/data/models/teki_model/supplier.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';

class AccountsReceivable {
  final int? id;
  final int? diasCredito;
  final bool? extendido;
  final int? diasExtendidos;
  final DateTime? fechaVencimiento;
  final String? estadoCredito;
  final List<AccountsReceivableDetail>? accountsReceivableDetails;
  final Company? empresa;
  final String? tipoCuenta;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;
  final Ticket? ticket;
  final String? serie;
  final int? numero;
  final String? fechaEmision;
  final DateTime? fechaEmisionDate;
  final Customer? cliente;
  final User? vendedor;
  final String? razonSocialEmisor;
  final String? codigoLocalAnexoEmisor;
  final String? tipoDocumentoReceptor;
  final String? numeroDocumentoReceptor;
  final String? denominacionReceptor;
  final String? direccionReceptor;
  final String? emailReceptor;
  final String? telefonoReceptor;
  final String? tipoComprobante;
  final String? codigoMoneda;
  final double? totalVenta;
  final double? totalVentaCredito;
  final Office? puntoVenta;
  final Purchase? purchase;
  final SaleStation? estacionVenta;
  final Supplier? proveedor;
  final String? uuid;
  final bool? anulado;
  final String? motivoAnulacion;
  final bool? estado;
  final String? comprobante;
  final String? numeroDocumentoProveedor;
  final String? nombreProveedor;
  final double? totalCompra;
  final double? montoPagado;
  final double? montoRestante;

  AccountsReceivable({
    this.id,
    this.diasCredito,
    this.extendido,
    this.diasExtendidos,
    this.fechaVencimiento,
    this.estadoCredito,
    this.accountsReceivableDetails,
    this.empresa,
    this.tipoCuenta,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
    this.ticket,
    this.serie,
    this.numero,
    this.fechaEmision,
    this.fechaEmisionDate,
    this.cliente,
    this.vendedor,
    this.razonSocialEmisor,
    this.codigoLocalAnexoEmisor,
    this.tipoDocumentoReceptor,
    this.numeroDocumentoReceptor,
    this.denominacionReceptor,
    this.direccionReceptor,
    this.emailReceptor,
    this.telefonoReceptor,
    this.tipoComprobante,
    this.codigoMoneda,
    this.totalVenta,
    this.totalVentaCredito,
    this.puntoVenta,
    this.purchase,
    this.estacionVenta,
    this.proveedor,
    this.uuid,
    this.anulado,
    this.motivoAnulacion,
    this.estado,
    this.comprobante,
    this.numeroDocumentoProveedor,
    this.nombreProveedor,
    this.totalCompra,
    this.montoPagado,
    this.montoRestante,
  });

  factory AccountsReceivable.fromJson(Map<String, dynamic> json) => AccountsReceivable(
        id: json['id'],
        diasCredito: json['diasCredito'],
        extendido: json['extendido'],
        diasExtendidos: json['diasExtendidos'],
        fechaVencimiento: json['fechaVencimiento'] != null ? DateTime.parse(json['fechaVencimiento']) : null,
        estadoCredito: json['estadoCredito'],
        accountsReceivableDetails: json['accountsReceivableDetails'] != null
            ? List<AccountsReceivableDetail>.from(json['accountsReceivableDetails'].map((x) => AccountsReceivableDetail.fromJson(x)))
            : null,
        empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        tipoCuenta: json['tipoCuenta'],
        eliminado: json['eliminado'],
        createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
        ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
        serie: json['serie'],
        numero: json['numero'],
        fechaEmision: json['fechaEmision'],
        fechaEmisionDate: json['fechaEmisionDate'] != null ? DateTime.parse(json['fechaEmisionDate']) : null,
        cliente: json['cliente'] != null ? Customer.fromJson(json['cliente']) : null,
        vendedor: json['vendedor'] != null ? User.fromJson(json['vendedor']) : null,
        razonSocialEmisor: json['razonSocialEmisor'],
        codigoLocalAnexoEmisor: json['codigoLocalAnexoEmisor'],
        tipoDocumentoReceptor: json['tipoDocumentoReceptor'],
        numeroDocumentoReceptor: json['numeroDocumentoReceptor'],
        denominacionReceptor: json['denominacionReceptor'],
        direccionReceptor: json['direccionReceptor'],
        emailReceptor: json['emailReceptor'],
        telefonoReceptor: json['telefonoReceptor'],
        tipoComprobante: json['tipoComprobante'],
        codigoMoneda: json['codigoMoneda'],
        totalVenta: (json['totalVenta'] as num?)?.toDouble(),
        totalVentaCredito: (json['totalVentaCredito'] as num?)?.toDouble(),
        puntoVenta: json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
        purchase: json['purchase'] != null ? Purchase.fromJson(json['purchase']) : null,
        estacionVenta: json['estacionVenta'] != null ? SaleStation.fromJson(json['estacionVenta']) : null,
        proveedor: json['proveedor'] != null ? Supplier.fromJson(json['proveedor']) : null,
        uuid: json['uuid'],
        anulado: json['anulado'],
        motivoAnulacion: json['motivoAnulacion'],
        estado: json['estado'],
        comprobante: json['comprobante'],
        numeroDocumentoProveedor: json['numeroDocumentoProveedor'],
        nombreProveedor: json['nombreProveedor'],
        totalCompra: (json['totalCompra'] as num?)?.toDouble(),
        montoPagado: (json['montoPagado'] as num?)?.toDouble(),
        montoRestante: (json['montoRestante'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'diasCredito': diasCredito,
        'extendido': extendido,
        'diasExtendidos': diasExtendidos,
        'fechaVencimiento': fechaVencimiento?.toIso8601String(),
        'estadoCredito': estadoCredito,
        'accountsReceivableDetails': accountsReceivableDetails?.map((x) => x.toJson()).toList(),
        'empresa': empresa?.toJson(),
        'tipoCuenta': tipoCuenta,
        'eliminado': eliminado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
        'ticket': ticket?.toJson(),
        'serie': serie,
        'numero': numero,
        'fechaEmision': fechaEmision,
        'fechaEmisionDate': fechaEmisionDate?.toIso8601String(),
        'cliente': cliente?.toJson(),
        'vendedor': vendedor?.toJson(),
        'razonSocialEmisor': razonSocialEmisor,
        'codigoLocalAnexoEmisor': codigoLocalAnexoEmisor,
        'tipoDocumentoReceptor': tipoDocumentoReceptor,
        'numeroDocumentoReceptor': numeroDocumentoReceptor,
        'denominacionReceptor': denominacionReceptor,
        'direccionReceptor': direccionReceptor,
        'emailReceptor': emailReceptor,
        'telefonoReceptor': telefonoReceptor,
        'tipoComprobante': tipoComprobante,
        'codigoMoneda': codigoMoneda,
        'totalVenta': totalVenta,
        'totalVentaCredito': totalVentaCredito,
        'puntoVenta': puntoVenta?.toJson(),
        'purchase': purchase?.toJson(),
        'estacionVenta': estacionVenta?.toJson(),
        'proveedor': proveedor?.toJson(),
        'uuid': uuid,
        'anulado': anulado,
        'motivoAnulacion': motivoAnulacion,
        'estado': estado,
        'comprobante': comprobante,
        'numeroDocumentoProveedor': numeroDocumentoProveedor,
        'nombreProveedor': nombreProveedor,
        'totalCompra': totalCompra,
        'montoPagado': montoPagado,
        'montoRestante': montoRestante,
      };
}
