import 'package:teki_app/src/data/models/teki_model/caja_metodo_pago_balance.dart';

/// Resumen agregado de caja para un rango de fechas (modo reporte).
/// Espejo de CajaResumenDto del backend: todo viene calculado del servidor.
class CajaResumen {
  final List<TotalMonedaResumen> totales;
  final List<ConceptoResumen> porConcepto;
  final List<CajaMetodoPagoBalance> porMetodoPago;
  final List<SeriePuntoResumen> serie;

  /// 'DIA' o 'MES' según el tamaño del rango.
  final String? serieBucket;
  final int totalCajas;
  final int cajasAbiertas;

  const CajaResumen({
    this.totales = const [],
    this.porConcepto = const [],
    this.porMetodoPago = const [],
    this.serie = const [],
    this.serieBucket,
    this.totalCajas = 0,
    this.cajasAbiertas = 0,
  });

  factory CajaResumen.fromJson(Map<String, dynamic> json) {
    return CajaResumen(
      totales: _list(json['totales'], TotalMonedaResumen.fromJson),
      porConcepto: _list(json['porConcepto'], ConceptoResumen.fromJson),
      porMetodoPago: _list(json['porMetodoPago'], CajaMetodoPagoBalance.fromJson),
      serie: _list(json['serie'], SeriePuntoResumen.fromJson),
      serieBucket: json['serieBucket'] as String?,
      totalCajas: (json['totalCajas'] as num?)?.toInt() ?? 0,
      cajasAbiertas: (json['cajasAbiertas'] as num?)?.toInt() ?? 0,
    );
  }

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
    if (raw == null) return [];
    return (raw as List).map((e) => parse(e as Map<String, dynamic>)).toList();
  }

  /// Monedas presentes en los totales, con PEN primero.
  List<String> get monedas => totales.map((t) => t.moneda).toList()
    ..sort((a, b) => a == 'PEN' ? -1 : 1);

  TotalMonedaResumen? totalDe(String moneda) {
    for (final t in totales) {
      if (t.moneda == moneda) return t;
    }
    return null;
  }

  /// Conceptos de la moneda, ordenados: rendimiento primero (ingresos y
  /// luego egresos, por monto desc) y los operativos (apertura/retiro) al
  /// final como informativos.
  List<ConceptoResumen> conceptosDe(String moneda) {
    final lista = porConcepto.where((c) => c.moneda == moneda).toList()
      ..sort((a, b) {
        if (a.esOperativo != b.esOperativo) return a.esOperativo ? 1 : -1;
        if (a.esIngreso != b.esIngreso) return a.esIngreso ? -1 : 1;
        return b.monto.compareTo(a.monto);
      });
    return lista;
  }
}

class TotalMonedaResumen {
  final String moneda;
  final double totalIngresos;
  final double totalEgresos;
  final double neto;

  const TotalMonedaResumen({
    required this.moneda,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.neto,
  });

  factory TotalMonedaResumen.fromJson(Map<String, dynamic> json) {
    return TotalMonedaResumen(
      moneda: json['moneda'] as String? ?? 'PEN',
      totalIngresos: (json['totalIngresos'] as num?)?.toDouble() ?? 0,
      totalEgresos: (json['totalEgresos'] as num?)?.toDouble() ?? 0,
      neto: (json['neto'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ConceptoResumen {
  final String concepto;
  final String tipo;
  final String moneda;
  final double monto;
  final int operaciones;

  const ConceptoResumen({
    required this.concepto,
    required this.tipo,
    required this.moneda,
    required this.monto,
    required this.operaciones,
  });

  factory ConceptoResumen.fromJson(Map<String, dynamic> json) {
    return ConceptoResumen(
      concepto: json['concepto'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      moneda: json['moneda'] as String? ?? 'PEN',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      operaciones: (json['operaciones'] as num?)?.toInt() ?? 0,
    );
  }

  bool get esIngreso => tipo == 'INGRESO';
  bool get esApertura => concepto == 'APERTURA_CAJA';
  bool get esRetiro => concepto == 'RETIRO_CAJA';

  /// Conceptos operativos (flotante de apertura, retiros al cofre): no son
  /// rendimiento del periodo y quedan fuera de todas las sumas del resumen.
  bool get esOperativo => esApertura || esRetiro;

  /// Etiqueta legible del concepto.
  String get etiqueta {
    switch (concepto) {
      case 'VENTAS':
        return 'Ventas';
      case 'OTROS_INGRESOS':
        return 'Otros ingresos';
      case 'COMPRAS':
        return 'Compras';
      case 'OTROS_EGRESOS':
        return 'Otros egresos';
      case 'RETIRO_CAJA':
        return 'Retiros de caja';
      case 'PROPINAS':
        return 'Propinas';
      case 'APERTURA_CAJA':
        return 'Apertura de caja';
      default:
        return concepto;
    }
  }
}

class SeriePuntoResumen {
  final String bucket;
  final String moneda;
  final double ingresos;
  final double egresos;

  const SeriePuntoResumen({
    required this.bucket,
    required this.moneda,
    required this.ingresos,
    required this.egresos,
  });

  factory SeriePuntoResumen.fromJson(Map<String, dynamic> json) {
    return SeriePuntoResumen(
      bucket: json['bucket'] as String? ?? '',
      moneda: json['moneda'] as String? ?? 'PEN',
      ingresos: (json['ingresos'] as num?)?.toDouble() ?? 0,
      egresos: (json['egresos'] as num?)?.toDouble() ?? 0,
    );
  }
}
