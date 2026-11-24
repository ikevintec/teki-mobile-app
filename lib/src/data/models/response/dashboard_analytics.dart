// Modelos de los endpoints de analíticas del dashboard (paridad web:
// dashboard.service.ts → /total-categories, /sales-by-schedule y
// /summary-vendedores). Ventas por mes ya existe: MonthlySales.

double _numToDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// Total vendido por categoría de producto (GET /total-categories).
class TotalCategory {
  final String categoria;
  final double total;

  const TotalCategory({required this.categoria, required this.total});

  factory TotalCategory.fromJson(Map<String, dynamic> json) => TotalCategory(
        categoria: json['categoria'] as String? ?? 'No categorizado',
        total: _numToDouble(json['total']),
      );
}

/// Ventas por franja horaria y día de la semana (GET /sales-by-schedule).
class ScheduleSale {
  final String franjaHoraria;
  final String diaSemana;
  final int cantidadVentas;
  final double totalVentas;

  const ScheduleSale({
    required this.franjaHoraria,
    required this.diaSemana,
    required this.cantidadVentas,
    required this.totalVentas,
  });

  factory ScheduleSale.fromJson(Map<String, dynamic> json) => ScheduleSale(
        franjaHoraria:
            (json['franjaHoraria'] ?? json['franja'] ?? '-') as String,
        diaSemana: (json['diaSemana'] ?? json['dia'] ?? '-') as String,
        cantidadVentas: (json['cantidadVentas'] as num?)?.toInt() ?? 0,
        totalVentas: _numToDouble(json['totalVentas']),
      );
}

/// Resumen de ventas por vendedor (GET /summary-vendedores, paginado).
class VendorSummary {
  final String nombreVendedor;
  final int cantidadVentas;
  final double totalVentas;

  const VendorSummary({
    required this.nombreVendedor,
    required this.cantidadVentas,
    required this.totalVentas,
  });

  factory VendorSummary.fromJson(Map<String, dynamic> json) => VendorSummary(
        nombreVendedor: json['nombreVendedor'] as String? ?? 'No registrado',
        cantidadVentas: (json['cantidadVentas'] as num?)?.toInt() ?? 0,
        totalVentas: _numToDouble(json['totalVentas']),
      );
}
