import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/utils/formats.dart';

class PagoYape {
  final int? id;
  final String nombrePagador;
  final double monto;
  final String codigoOperacion;
  final NotificationAppType? tipoApp;
  final DateTime? fechaRegistro;
  final bool validado;

  const PagoYape({
    this.id,
    required this.nombrePagador,
    required this.monto,
    required this.codigoOperacion,
    this.tipoApp,
    this.fechaRegistro,
    this.validado = false,
  });

  factory PagoYape.fromJson(Map<String, dynamic> json) => PagoYape(
    id: (json['id'] as num?)?.toInt(),
    nombrePagador: json['nombrePagador']?.toString() ?? '',
    monto: _parseDouble(json['monto']),
    codigoOperacion: json['codigoOperacion']?.toString() ?? '',
    tipoApp: json['tipoApp'] == null
        ? null
        : NotificationAppType.fromCode(json['tipoApp'].toString()),
    fechaRegistro: parseDateTimeFlexible(json['fechaRegistro']),
    validado: json['validado'] == true,
  );

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PagoYapePage {
  final List<PagoYape> content;
  final int number;
  final int totalPages;
  final int totalElements;
  final bool last;
  final bool first;

  const PagoYapePage({
    this.content = const [],
    this.number = 0,
    this.totalPages = 0,
    this.totalElements = 0,
    this.last = true,
    this.first = true,
  });

  factory PagoYapePage.fromJson(Map<String, dynamic> json) => PagoYapePage(
    content: (json['content'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => PagoYape.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    number: (json['number'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    last: json['last'] == true,
    first: json['first'] != false,
  );
}
