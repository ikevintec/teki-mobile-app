import 'package:teki_app/src/data/models/teki_model/inventory_transfer_detail.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class InventoryTransfer {
  final int? id;
  final User? usuarioSolicitud;
  final User? usuarioAtencion;
  final User? usuarioRecepcion;
  final DateTime? fechaSolicitud;
  final DateTime? fechaAtencion;
  final DateTime? fechaRecepcion;
  final String? comentarioSolicitud;
  final String? comentarioAtencion;
  final String? comentarioRecepcion;
  final String? estadoTraslado;
  final Office? puntoVentaOrigen;
  final Office? puntoVentaDestino;
  final List<InventoryTransferDetail> items;
  final String? uuid;

  const InventoryTransfer({
    this.id,
    this.usuarioSolicitud,
    this.usuarioAtencion,
    this.usuarioRecepcion,
    this.fechaSolicitud,
    this.fechaAtencion,
    this.fechaRecepcion,
    this.comentarioSolicitud,
    this.comentarioAtencion,
    this.comentarioRecepcion,
    this.estadoTraslado,
    this.puntoVentaOrigen,
    this.puntoVentaDestino,
    this.items = const [],
    this.uuid,
  });

  factory InventoryTransfer.fromJson(Map<String, dynamic> json) =>
      InventoryTransfer(
        id: json['id'] as int?,
        usuarioSolicitud: json['usuarioSolicitud'] is Map<String, dynamic>
            ? User.fromJson(json['usuarioSolicitud'] as Map<String, dynamic>)
            : null,
        usuarioAtencion: json['usuarioAtencion'] is Map<String, dynamic>
            ? User.fromJson(json['usuarioAtencion'] as Map<String, dynamic>)
            : null,
        usuarioRecepcion: json['usuarioRecepcion'] is Map<String, dynamic>
            ? User.fromJson(json['usuarioRecepcion'] as Map<String, dynamic>)
            : null,
        fechaSolicitud: parseDateTimeFlexible(json['fechaSolicitud']),
        fechaAtencion: parseDateTimeFlexible(json['fechaAtencion']),
        fechaRecepcion: parseDateTimeFlexible(json['fechaRecepcion']),
        comentarioSolicitud: json['comentarioSolicitud']?.toString(),
        comentarioAtencion: json['comentarioAtencion']?.toString(),
        comentarioRecepcion: json['comentarioRecepcion']?.toString(),
        estadoTraslado: json['estadoTraslado']?.toString(),
        puntoVentaOrigen: json['puntoVentaOrigen'] is Map<String, dynamic>
            ? Office.fromJson(json['puntoVentaOrigen'] as Map<String, dynamic>)
            : null,
        puntoVentaDestino: json['puntoVentaDestino'] is Map<String, dynamic>
            ? Office.fromJson(json['puntoVentaDestino'] as Map<String, dynamic>)
            : null,
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(InventoryTransferDetail.fromJson)
            .toList(),
        uuid: json['uuid']?.toString(),
      );

  double get cantidadSolicitadaTotal =>
      items.fold(0, (total, item) => total + (item.cantidadSolicitud ?? 0));
}

class DirectInventoryTransferRequest {
  final int idPuntoVentaOrigen;
  final int idPuntoVentaDestino;
  final String comentarioSolicitud;
  final List<DirectInventoryTransferItem> items;

  const DirectInventoryTransferRequest({
    required this.idPuntoVentaOrigen,
    required this.idPuntoVentaDestino,
    required this.comentarioSolicitud,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'puntoVentaOrigen': {'id': idPuntoVentaOrigen},
    'puntoVentaDestino': {'id': idPuntoVentaDestino},
    'comentarioSolicitud': comentarioSolicitud,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class DirectInventoryTransferItem {
  final int idProducto;
  final double cantidadSolicitud;
  final List<DirectInventoryTransferBatch> lotes;

  const DirectInventoryTransferItem({
    required this.idProducto,
    required this.cantidadSolicitud,
    this.lotes = const [],
  });

  Map<String, dynamic> toJson() => {
    'producto': {'id': idProducto},
    'cantidadSolicitud': cantidadSolicitud,
    'lotes': lotes.map((lote) => lote.toJson()).toList(),
  };
}

class DirectInventoryTransferBatch {
  final int idLote;
  final double cantidadSolicitud;

  const DirectInventoryTransferBatch({
    required this.idLote,
    this.cantidadSolicitud = 1,
  });

  Map<String, dynamic> toJson() => {
    'lote': {'id': idLote},
    'cantidadSolicitud': cantidadSolicitud,
  };
}
