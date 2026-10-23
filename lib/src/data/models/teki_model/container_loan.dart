/// Préstamo de envases retornables a un cliente (`/container-loans`).
class ContainerLoan {
  final int? id;
  final int? customerId;
  final String? customer;
  final String? document;
  final int? officeId;
  final String? office;
  final String? container;
  final String? ticket;
  final double quantity;
  final double returnedQuantity;
  final double pendingQuantity;
  final double pendingValue;
  final String? currency;
  final DateTime? createdOn;
  final DateTime? loanedOn;
  final bool cancelled;
  final bool openingBalance;
  final bool? stockAlreadyDeducted;
  final String? note;

  const ContainerLoan({
    this.id,
    this.customerId,
    this.customer,
    this.document,
    this.officeId,
    this.office,
    this.container,
    this.ticket,
    this.quantity = 0,
    this.returnedQuantity = 0,
    this.pendingQuantity = 0,
    this.pendingValue = 0,
    this.currency,
    this.createdOn,
    this.loanedOn,
    this.cancelled = false,
    this.openingBalance = false,
    this.stockAlreadyDeducted,
    this.note,
  });

  factory ContainerLoan.fromJson(Map<String, dynamic> json) => ContainerLoan(
    id: json['id'],
    customerId: json['customerId'],
    customer: json['customer'],
    document: json['document'],
    officeId: json['officeId'],
    office: json['office'],
    container: json['container'],
    ticket: json['ticket'],
    quantity: (json['quantity'] ?? 0).toDouble(),
    returnedQuantity: (json['returnedQuantity'] ?? 0).toDouble(),
    pendingQuantity: (json['pendingQuantity'] ?? 0).toDouble(),
    pendingValue: (json['pendingValue'] ?? 0).toDouble(),
    currency: json['currency'],
    createdOn: _date(json['createdOn']),
    loanedOn: _date(json['loanedOn']),
    cancelled: json['cancelled'] == true,
    openingBalance: json['openingBalance'] == true,
    stockAlreadyDeducted: json['stockAlreadyDeducted'],
    note: json['note'],
  );
}

/// Devolución (parcial) de un préstamo. `requestId` evita duplicados al reintentar.
class ContainerReturn {
  final int? id;
  final double quantity;
  final int? officeId;
  final String? requestId;
  final String? note;
  final String? office;
  final DateTime? createdOn;
  final DateTime? cancelledOn;

  const ContainerReturn({
    this.id,
    required this.quantity,
    this.officeId,
    this.requestId,
    this.note,
    this.office,
    this.createdOn,
    this.cancelledOn,
  });

  factory ContainerReturn.fromJson(Map<String, dynamic> json) =>
      ContainerReturn(
        id: json['id'],
        quantity: (json['quantity'] ?? 0).toDouble(),
        officeId: json['officeId'],
        note: json['note'],
        office: json['office'],
        createdOn: _date(json['createdOn']),
        cancelledOn: _date(json['cancelledOn']),
      );

  Map<String, dynamic> toJson() => {
    'quantity': quantity,
    'officeId': officeId,
    'requestId': requestId,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

/// Total pendiente por moneda.
class ContainerLoanTotal {
  final String? currency;
  final double quantity;
  final double value;

  const ContainerLoanTotal({this.currency, this.quantity = 0, this.value = 0});

  factory ContainerLoanTotal.fromJson(Map<String, dynamic> json) =>
      ContainerLoanTotal(
        currency: json['currency'],
        quantity: (json['quantity'] ?? 0).toDouble(),
        value: (json['value'] ?? 0).toDouble(),
      );
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// Producto lleno configurado como retornable, para cargar préstamos anteriores.
/// `unitCost` es el costo actual del envase, sugerido como costo histórico.
class ContainerOpeningProduct {
  final int id;
  final String? name;
  final String? container;
  final double? unitCost;
  final String currency;

  const ContainerOpeningProduct({
    required this.id,
    this.name,
    this.container,
    this.unitCost,
    this.currency = 'PEN',
  });

  factory ContainerOpeningProduct.fromJson(Map<String, dynamic> json) =>
      ContainerOpeningProduct(
        id: json['id'],
        name: json['name'],
        container: json['container'],
        unitCost: (json['unitCost'] as num?)?.toDouble(),
        currency: json['currency'] ?? 'PEN',
      );
}

/// Saldo pendiente anterior al uso del módulo. No genera venta. Reintentar con
/// el mismo `requestId` y los mismos datos no duplica saldo ni movimiento.
class ContainerOpening {
  final int customerId;
  final int officeId;
  final int productId;
  final int quantity;
  final double unitCost;
  final DateTime loanedOn;
  final bool stockAlreadyDeducted;
  final String requestId;
  final String? note;

  const ContainerOpening({
    required this.customerId,
    required this.officeId,
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.loanedOn,
    required this.stockAlreadyDeducted,
    required this.requestId,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'officeId': officeId,
    'productId': productId,
    'quantity': quantity,
    'unitCost': unitCost,
    'loanedOn': loanedOn.toUtc().toIso8601String(),
    'stockAlreadyDeducted': stockAlreadyDeducted,
    'requestId': requestId,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}
