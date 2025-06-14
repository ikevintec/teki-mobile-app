import 'package:teki_app/src/data/models/teki_model/attachedCompany.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/purchaseDetail.dart';

class BatchProduct {
  final int? id;
  final double? cantidad;
  final double? cantidadCompra;
  final String? tipoLote;
  final String? serie;
  final String? talla;
  final String? color;
  final DateTime? fechaFabricacion;
  final DateTime? fechaVencimiento;
  final double? precioCompra;
  final bool? modificado;
  final bool? eliminado;
  final PurchaseDetail? compraLote;
  final Company? empresa;
  final AttachedCompany? empresaAdjunta;

  BatchProduct({
    this.id,
    this.cantidad,
    this.cantidadCompra,
    this.tipoLote,
    this.serie,
    this.talla,
    this.color,
    this.fechaFabricacion,
    this.fechaVencimiento,
    this.precioCompra,
    this.modificado,
    this.eliminado,
    this.compraLote,
    this.empresa,
    this.empresaAdjunta,
  });

  factory BatchProduct.fromJson(Map<String, dynamic> json) => BatchProduct(
    id: json['id'],
    cantidad: (json['cantidad'] as num?)?.toDouble(),
    cantidadCompra: (json['cantidadCompra'] as num?)?.toDouble(),
    tipoLote: json['tipoLote'],
    serie: json['serie'],
    talla: json['talla'],
    color: json['color'],
    fechaFabricacion: json['fechaFabricacion'] != null ? DateTime.parse(json['fechaFabricacion']) : null,
    fechaVencimiento: json['fechaVencimiento'] != null ? DateTime.parse(json['fechaVencimiento']) : null,
    precioCompra: (json['precioCompra'] as num?)?.toDouble(),
    modificado: json['modificado'],
    eliminado: json['eliminado'],
    compraLote: json['compraLote'] != null ? PurchaseDetail.fromJson(json['compraLote']) : null,
    empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
    empresaAdjunta: json['empresaAdjunta'] != null ? AttachedCompany.fromJson(json['empresaAdjunta']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cantidad': cantidad,
    'cantidadCompra': cantidadCompra,
    'tipoLote': tipoLote,
    'serie': serie,
    'talla': talla,
    'color': color,
    'fechaFabricacion': fechaFabricacion?.toIso8601String(),
    'fechaVencimiento': fechaVencimiento?.toIso8601String(),
    'precioCompra': precioCompra,
    'modificado': modificado,
    'eliminado': eliminado,
    'compraLote': compraLote?.toJson(),
    'empresa': empresa?.toJson(),
    'empresaAdjunta': empresaAdjunta?.toJson(),
  };
}
