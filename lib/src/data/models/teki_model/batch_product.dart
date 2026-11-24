import 'package:teki_app/src/data/models/teki_model/attached_company.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_record.dart';
import 'package:teki_app/src/data/models/teki_model/purchase_detail.dart';
import 'package:teki_app/src/utils/formats.dart';

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
  final List<InventoryRecord>? registros;

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
    this.registros,
  });

  factory BatchProduct.fromJson(Map<String, dynamic> json) => BatchProduct(
    id: json['id'],
    cantidad: (json['cantidad'] as num?)?.toDouble(),
    cantidadCompra: (json['cantidadCompra'] as num?)?.toDouble(),
    tipoLote: json['tipoLote'],
    serie: json['serie'],
    talla: json['talla'],
    color: json['color'],
    fechaFabricacion: json['fechaFabricacion'] != null ? parseDateTimeFlexible(json['fechaFabricacion']) : null,
    fechaVencimiento: json['fechaVencimiento'] != null ? parseDateTimeFlexible(json['fechaVencimiento']) : null,
    precioCompra: (json['precioCompra'] as num?)?.toDouble(),
    modificado: json['modificado'],
    eliminado: json['eliminado'],
    compraLote: json['compraLote'] != null ? PurchaseDetail.fromJson(json['compraLote']) : null,
    empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
    empresaAdjunta: json['empresaAdjunta'] != null ? AttachedCompany.fromJson(json['empresaAdjunta']) : null,
    registros: json['registros'] != null
        ? List<InventoryRecord>.from(
            json['registros'].map((x) => InventoryRecord.fromJson(x)))
        : [],
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
    'registros': registros != null ? registros!.map((x) => x.toJson()).toList() : [],
  };
}
