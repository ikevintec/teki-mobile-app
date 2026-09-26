class InventorySyncIssue {
  final int idInventory;
  final int idProducto;
  final String producto;
  final String? codigoProducto;
  final String tipoLote;
  final int? idPuntoVenta;
  final String? puntoVenta;
  final double stock;
  final double cantidadLotes;
  final double diferencia;
  final int lotesConSaldo;
  final int lotesNegativos;

  const InventorySyncIssue({
    required this.idInventory,
    required this.idProducto,
    required this.producto,
    this.codigoProducto,
    required this.tipoLote,
    this.idPuntoVenta,
    this.puntoVenta,
    required this.stock,
    required this.cantidadLotes,
    required this.diferencia,
    required this.lotesConSaldo,
    required this.lotesNegativos,
  });

  factory InventorySyncIssue.fromJson(Map<String, dynamic> json) =>
      InventorySyncIssue(
        idInventory: (json['idInventory'] as num).toInt(),
        idProducto: (json['idProducto'] as num).toInt(),
        producto: json['producto'] as String? ?? '-',
        codigoProducto: json['codigoProducto'] as String?,
        tipoLote: json['tipoLote'] as String? ?? 'LOTE',
        idPuntoVenta: (json['idPuntoVenta'] as num?)?.toInt(),
        puntoVenta: json['puntoVenta'] as String?,
        stock: (json['stock'] as num?)?.toDouble() ?? 0,
        cantidadLotes: (json['cantidadLotes'] as num?)?.toDouble() ?? 0,
        diferencia: (json['diferencia'] as num?)?.toDouble() ?? 0,
        lotesConSaldo: (json['lotesConSaldo'] as num?)?.toInt() ?? 0,
        lotesNegativos: (json['lotesNegativos'] as num?)?.toInt() ?? 0,
      );

  bool get quedariaEnCero => cantidadLotes == 0 && stock > 0;
}

class InventorySyncSummary {
  final int total;
  final int productos;
  final double unidades;

  const InventorySyncSummary({
    this.total = 0,
    this.productos = 0,
    this.unidades = 0,
  });

  factory InventorySyncSummary.fromJson(Map<String, dynamic> json) =>
      InventorySyncSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        productos: (json['productos'] as num?)?.toInt() ?? 0,
        unidades: (json['unidades'] as num?)?.toDouble() ?? 0,
      );
}

class InventorySyncFixResult {
  final int corregidos;
  final int sinCambios;
  final List<String> errores;

  const InventorySyncFixResult({
    this.corregidos = 0,
    this.sinCambios = 0,
    this.errores = const [],
  });

  factory InventorySyncFixResult.fromJson(Map<String, dynamic> json) =>
      InventorySyncFixResult(
        corregidos: (json['corregidos'] as num?)?.toInt() ?? 0,
        sinCambios: (json['sinCambios'] as num?)?.toInt() ?? 0,
        errores:
            (json['errores'] as List?)
                ?.map((error) => error.toString())
                .toList() ??
            const [],
      );
}

class InventorySyncPage {
  final List<InventorySyncIssue> content;
  final int totalElements;
  final bool last;
  final int number;

  const InventorySyncPage({
    this.content = const [],
    this.totalElements = 0,
    this.last = true,
    this.number = 0,
  });

  factory InventorySyncPage.fromJson(Map<String, dynamic> json) =>
      InventorySyncPage(
        content:
            (json['content'] as List?)
                ?.whereType<Map>()
                .map(
                  (item) => InventorySyncIssue.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList() ??
            const [],
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        last: json['last'] as bool? ?? true,
        number: (json['number'] as num?)?.toInt() ?? 0,
      );
}
