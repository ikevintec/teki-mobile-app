import 'package:teki_app/src/data/models/teki_model/product.dart';

class InventoryTransferDetail {
  final int? id;
  final Product? producto;
  final double? cantidadSolicitud;
  final double? cantidadAtencion;
  final double? cantidadRecepcion;

  const InventoryTransferDetail({
    this.id,
    this.producto,
    this.cantidadSolicitud,
    this.cantidadAtencion,
    this.cantidadRecepcion,
  });

  factory InventoryTransferDetail.fromJson(Map<String, dynamic> json) =>
      InventoryTransferDetail(
        id: json['id'] as int?,
        producto: json['producto'] is Map<String, dynamic>
            ? Product.fromJson(json['producto'] as Map<String, dynamic>)
            : null,
        cantidadSolicitud: (json['cantidadSolicitud'] as num?)?.toDouble(),
        cantidadAtencion: (json['cantidadAtencion'] as num?)?.toDouble(),
        cantidadRecepcion: (json['cantidadRecepcion'] as num?)?.toDouble(),
      );
}
