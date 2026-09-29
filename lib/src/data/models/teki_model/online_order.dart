import 'package:teki_app/src/utils/formats.dart';

class OnlineOrder {
  final int? id;
  final String? uuid;
  final int? numeroPedido;
  final String? tipo;
  final String? estado;
  final String? nombreCliente;
  final String? telefonoCliente;
  final String? emailCliente;
  final String? tipoDocumentoCliente;
  final String? numeroDocumentoCliente;
  final String? tipoComprobante;
  final String? metodoPago;
  final double? montoEfectivo;
  final String? imagenYape;
  final String? tipoEntrega;
  final String? direccionEntrega;
  final String? referenciaEntrega;
  final String? moneda;
  final double? subtotal;
  final double? montoDelivery;
  final double? total;
  final String? observacion;
  final String? mensajeAceptacionPedido;
  final String? mensajeRechazoPedido;
  final int? idOrderRestaurant;
  final OnlineOrderResponsible? responsable;
  final DateTime? tiempoAtencion;
  final DateTime? createdOn;
  final DateTime? updatedOn;
  final List<OnlineOrderItem> items;

  const OnlineOrder({
    this.id,
    this.uuid,
    this.numeroPedido,
    this.tipo,
    this.estado,
    this.nombreCliente,
    this.telefonoCliente,
    this.emailCliente,
    this.tipoDocumentoCliente,
    this.numeroDocumentoCliente,
    this.tipoComprobante,
    this.metodoPago,
    this.montoEfectivo,
    this.imagenYape,
    this.tipoEntrega,
    this.direccionEntrega,
    this.referenciaEntrega,
    this.moneda,
    this.subtotal,
    this.montoDelivery,
    this.total,
    this.observacion,
    this.mensajeAceptacionPedido,
    this.mensajeRechazoPedido,
    this.idOrderRestaurant,
    this.responsable,
    this.tiempoAtencion,
    this.createdOn,
    this.updatedOn,
    this.items = const [],
  });

  factory OnlineOrder.fromJson(Map<String, dynamic> json) => OnlineOrder(
    id: (json['id'] as num?)?.toInt(),
    uuid: json['uuid']?.toString(),
    numeroPedido: (json['numeroPedido'] as num?)?.toInt(),
    tipo: json['tipo']?.toString(),
    estado: json['estado']?.toString(),
    nombreCliente: json['nombreCliente']?.toString(),
    telefonoCliente: json['telefonoCliente']?.toString(),
    emailCliente: json['emailCliente']?.toString(),
    tipoDocumentoCliente: json['tipoDocumentoCliente']?.toString(),
    numeroDocumentoCliente: json['numeroDocumentoCliente']?.toString(),
    tipoComprobante: json['tipoComprobante']?.toString(),
    metodoPago: json['metodoPago']?.toString(),
    montoEfectivo: (json['montoEfectivo'] as num?)?.toDouble(),
    imagenYape: json['imagenYape']?.toString(),
    tipoEntrega: json['tipoEntrega']?.toString(),
    direccionEntrega: json['direccionEntrega']?.toString(),
    referenciaEntrega: json['referenciaEntrega']?.toString(),
    moneda: json['moneda']?.toString(),
    subtotal: (json['subtotal'] as num?)?.toDouble(),
    montoDelivery: (json['montoDelivery'] as num?)?.toDouble(),
    total: (json['total'] as num?)?.toDouble(),
    observacion: json['observacion']?.toString(),
    mensajeAceptacionPedido: json['mensajeAceptacionPedido']?.toString(),
    mensajeRechazoPedido: json['mensajeRechazoPedido']?.toString(),
    idOrderRestaurant: (json['idOrderRestaurant'] as num?)?.toInt(),
    responsable: json['responsable'] is Map<String, dynamic>
        ? OnlineOrderResponsible.fromJson(
            json['responsable'] as Map<String, dynamic>,
          )
        : null,
    tiempoAtencion: parseDateTimeFlexible(json['tiempoAtencion']),
    createdOn: parseDateTimeFlexible(json['createdOn']),
    updatedOn: parseDateTimeFlexible(json['updatedOn']),
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OnlineOrderItem.fromJson)
        .toList(),
  );

  OnlineOrder copyWith({String? estado}) => OnlineOrder(
    id: id,
    uuid: uuid,
    numeroPedido: numeroPedido,
    tipo: tipo,
    estado: estado ?? this.estado,
    nombreCliente: nombreCliente,
    telefonoCliente: telefonoCliente,
    emailCliente: emailCliente,
    tipoDocumentoCliente: tipoDocumentoCliente,
    numeroDocumentoCliente: numeroDocumentoCliente,
    tipoComprobante: tipoComprobante,
    metodoPago: metodoPago,
    montoEfectivo: montoEfectivo,
    imagenYape: imagenYape,
    tipoEntrega: tipoEntrega,
    direccionEntrega: direccionEntrega,
    referenciaEntrega: referenciaEntrega,
    moneda: moneda,
    subtotal: subtotal,
    montoDelivery: montoDelivery,
    total: total,
    observacion: observacion,
    mensajeAceptacionPedido: mensajeAceptacionPedido,
    mensajeRechazoPedido: mensajeRechazoPedido,
    idOrderRestaurant: idOrderRestaurant,
    responsable: responsable,
    tiempoAtencion: tiempoAtencion,
    createdOn: createdOn,
    updatedOn: updatedOn,
    items: items,
  );
}

class OnlineOrderItem {
  final int? id;
  final String? nombreProducto;
  final String? nombreVariante;
  final String? codigoProducto;
  final double cantidad;
  final double precioUnitario;
  final double precioTotal;
  final String? moneda;
  final String? nota;
  final List<OnlineOrderItemOption> opciones;

  const OnlineOrderItem({
    this.id,
    this.nombreProducto,
    this.nombreVariante,
    this.codigoProducto,
    this.cantidad = 0,
    this.precioUnitario = 0,
    this.precioTotal = 0,
    this.moneda,
    this.nota,
    this.opciones = const [],
  });

  factory OnlineOrderItem.fromJson(Map<String, dynamic> json) =>
      OnlineOrderItem(
        id: (json['id'] as num?)?.toInt(),
        nombreProducto: json['nombreProducto']?.toString(),
        nombreVariante: json['nombreVariante']?.toString(),
        codigoProducto: json['codigoProducto']?.toString(),
        cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
        precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0,
        precioTotal: (json['precioTotal'] as num?)?.toDouble() ?? 0,
        moneda: json['moneda']?.toString(),
        nota: (json['nota'] ?? json['observacion'])?.toString(),
        opciones: (json['opciones'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OnlineOrderItemOption.fromJson)
            .toList(),
      );
}

class OnlineOrderItemOption {
  final String? nombreGrupo;
  final String? nombreOpcion;
  final double cantidad;
  final double precioTotal;

  const OnlineOrderItemOption({
    this.nombreGrupo,
    this.nombreOpcion,
    this.cantidad = 0,
    this.precioTotal = 0,
  });

  factory OnlineOrderItemOption.fromJson(Map<String, dynamic> json) =>
      OnlineOrderItemOption(
        nombreGrupo: json['nombreGrupo']?.toString(),
        nombreOpcion: (json['nombreOpcion'] ?? json['nombreProductoOpcion'])
            ?.toString(),
        cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
        precioTotal: (json['precioTotal'] as num?)?.toDouble() ?? 0,
      );
}

class OnlineOrderResponsible {
  final String? nombreCompleto;
  final String? nombres;
  final String? apellidos;
  final String? username;

  const OnlineOrderResponsible({
    this.nombreCompleto,
    this.nombres,
    this.apellidos,
    this.username,
  });

  factory OnlineOrderResponsible.fromJson(Map<String, dynamic> json) =>
      OnlineOrderResponsible(
        nombreCompleto: json['nombreCompleto']?.toString(),
        nombres: json['nombres']?.toString(),
        apellidos: json['apellidos']?.toString(),
        username: json['username']?.toString(),
      );

  String get displayName {
    final fullName = nombreCompleto?.trim();
    if (fullName?.isNotEmpty == true) return fullName!;
    final joined = [
      nombres,
      apellidos,
    ].where((part) => part?.trim().isNotEmpty == true).join(' ');
    return joined.isNotEmpty ? joined : (username ?? '-');
  }
}
