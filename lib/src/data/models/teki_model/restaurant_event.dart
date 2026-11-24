class RestaurantEventType {
  static const String qrPendingApproval = 'COMANDA_QR_POR_APROBAR';
  static const String qrReviewed = 'COMANDA_QR_REVISADA';
  static const String onlineOrder = 'PEDIDO_ONLINE_NUEVO';
  static const String legacy = 'LEGACY';
}

class RestaurantEvent {
  final String type;
  final int? companyId;
  final int? officeId;
  final String? officeCode;
  final int? orderId;
  final int? tableId;
  final int? commandId;
  final int? userId;
  final int? timestamp;
  final String? status;
  final bool? isQr;
  final List<int> productionAreaIds;

  const RestaurantEvent({
    required this.type,
    this.companyId,
    this.officeId,
    this.officeCode,
    this.orderId,
    this.tableId,
    this.commandId,
    this.userId,
    this.timestamp,
    this.status,
    this.isQr,
    this.productionAreaIds = const [],
  });

  bool belongsToOffice(int? activeOfficeId) =>
      officeId == null || activeOfficeId == null || officeId == activeOfficeId;

  String get duplicateKey => '$type|$orderId|$commandId|$timestamp';

  static RestaurantEvent? fromSocket(
    dynamic raw, {
    required bool isOrderChannel,
  }) {
    dynamic value = raw;
    if (raw is Map && raw.containsKey('value')) {
      value = raw['value'];
    }
    if (value == null) return null;

    if (value is! Map) {
      return RestaurantEvent(
        type: isOrderChannel
            ? RestaurantEventType.onlineOrder
            : RestaurantEventType.legacy,
        companyId: _asInt(value),
      );
    }

    final data = Map<String, dynamic>.from(value);
    final areas = (data['zonas'] as List? ?? const [])
        .map(_asInt)
        .whereType<int>()
        .toList(growable: false);
    return RestaurantEvent(
      type:
          data['tipo']?.toString() ??
          (isOrderChannel
              ? RestaurantEventType.onlineOrder
              : RestaurantEventType.legacy),
      companyId: _asInt(data['idEmpresa']),
      officeId: _asInt(data['idPuntoVenta']),
      officeCode: data['codigoPuntoVenta']?.toString(),
      orderId: _asInt(data['idPedido']),
      tableId: _asInt(data['idMesa']),
      commandId: _asInt(data['idComanda']),
      userId: _asInt(data['idUsuario']),
      timestamp: _asInt(data['ts']),
      status: data['estado']?.toString(),
      isQr: data['esPorQr'] as bool?,
      productionAreaIds: areas,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
