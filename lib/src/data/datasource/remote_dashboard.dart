import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/daily_sales_summary.dart';
import 'package:teki_app/src/data/models/response/top_product.dart';
import 'package:teki_app/src/data/models/teki_model/total_counter.dart';
import 'package:teki_app/src/domain/datasource/dashboard_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteDashboardDatasource implements DashboardDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<TotalCounter> getSalesCount(int idPuntoVenta) async {
    try {
      final response = await dio.get('/tickets', queryParameters: {
        'pageNumber': '0',
        'perPage': '1',
        'filtroEstadoAnulacion': 'false',
        'sortOrder': '1',
        'sortField': 'fechaEmision',
        'idPuntoVenta': idPuntoVenta.toString(),
      });

      return TotalCounter.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error('❌ Ventas: $message');
    } catch (e) {
      return Future.error('❌ Ventas: ${e.toString()}');
    }
  }

  @override
  Future<TotalCounter> getCustomerCount() async {
    try {
      final response = await dio.get('/customers', queryParameters: {
        'paginacion': 'true',
        'pageNumber': '0',
        'perPage': '1',
      });

      return TotalCounter.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error('❌ Clientes: $message');
    } catch (e) {
      return Future.error('❌ Clientes: ${e.toString()}');
    }
  }

  /// ✅ Nuevo método: obtiene montos agrupados por moneda desde los tickets
  // Future<List<Map<String, dynamic>>> getAmountsByCurrency(
  //     Map<String, dynamic> params) async {
  //   try {
  //     final response = await dio.get('/tickets/list', queryParameters: params);

  //     final List<dynamic> tickets = response.data;

  //     if (tickets.isEmpty) {
  //       return [
  //         {'monto': 0, 'codigoMoneda': 'PEN'}
  //       ];
  //     }

  //     // Agrupar por 'codigoMoneda'
  //     final Map<String, List<Map<String, dynamic>>> grouped = {};
  //     for (var ticket in tickets) {
  //       final t = Map<String, dynamic>.from(ticket);
  //       final key = t['codigoMoneda'];
  //       grouped.putIfAbsent(key, () => []).add(t);
  //     }

  //     // Reducir por moneda
  //     final List<Map<String, dynamic>> result = [];
  //     grouped.forEach((moneda, items) {
  //       final montoTotal = items.fold<double>(0, (sum, t) {
  //         final total = (t['totalVenta'] ?? 0).toDouble();
  //         final tipo = t['tipoComprobante']?.toString();
  //         return sum + (tipo == '07' ? -total : total);
  //       });
  //       result.add({'monto': montoTotal, 'codigoMoneda': moneda});
  //     });

  //     return result;
  //   } on DioException catch (e) {
  //     final message =
  //         e.response?.data['message'] ?? e.message ?? 'Error al obtener montos';
  //     return Future.error('❌ Montos por moneda: $message');
  //   } catch (e) {
  //     return Future.error('❌ Montos por moneda: ${e.toString()}');
  //   }
  // }

  Future<List<Map<String, dynamic>>> getAmountsByCurrency(
      Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/tickets', queryParameters: params);

      final List<dynamic> tickets = response.data;

      if (tickets.isEmpty) {
        return [
          {'monto': 0.0, 'codigoMoneda': 'PEN'}
        ];
      }

      // Agrupar por código de moneda
      final Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var ticket in tickets) {
        final t = Map<String, dynamic>.from(ticket);
        final key = t['codigoMoneda'] ?? 'PEN';
        grouped.putIfAbsent(key, () => []).add(t);
      }

      // Reducir por moneda
      final List<Map<String, dynamic>> result = [];

      grouped.forEach((moneda, items) {
        final double montoTotal = items.fold(0.0, (sum, t) {
          final double total = (t['totalVenta'] ?? 0).toDouble();
          final String tipo = (t['tipoComprobante'] ?? '').toString();
          return sum + (tipo == '07' ? -total : total);
        });

        result.add({'monto': montoTotal, 'codigoMoneda': moneda});
      });

      return result;
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error al obtener montos';
      return Future.error('❌ Montos por moneda: $message');
    } catch (e) {
      return Future.error('❌ Montos por moneda: ${e.toString()}');
    }
  }

  @override
  Future<DailySalesSummary> getTodaySalesSummary(
      Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/tickets', queryParameters: params);
      final List<dynamic> tickets = response.data;

      final Map<String, double> montos = {};
      int count = 0;
      for (final ticket in tickets) {
        final t = Map<String, dynamic>.from(ticket);
        final moneda = (t['codigoMoneda'] ?? 'PEN') as String;
        final total = ((t['totalVenta'] ?? 0) as num).toDouble();
        final esNotaCredito = (t['tipoComprobante'] ?? '').toString() == '07';
        // Las NC restan monto y no cuentan como venta realizada.
        montos[moneda] = (montos[moneda] ?? 0) + (esNotaCredito ? -total : total);
        if (!esNotaCredito) count++;
      }

      if (montos.isEmpty) montos['PEN'] = 0;
      return DailySalesSummary(
        totalVentas: count,
        montos: montos.entries
            .map((e) => MontoMonedaVenta(moneda: e.key, monto: e.value))
            .toList(),
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error('❌ Ventas del día: $message');
    } catch (e) {
      return Future.error('❌ Ventas del día: ${e.toString()}');
    }
  }

  @override
  Future<List<TopProduct>> getTopProducts(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/products/top-orders', queryParameters: params);
      return (response.data as List)
          .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error('❌ Top productos: $message');
    } catch (e) {
      return Future.error('❌ Top productos: ${e.toString()}');
    }
  }
}
