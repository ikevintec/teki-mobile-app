import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/accounts_receivable_total_response.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivable.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivableDetail.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/domain/datasource/accounts_receivable_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteAccountsReceivable implements AccountsReceivableDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<List<AccountsReceivable>> getAccounts(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await dio.get(
        '/accounts-receivable',
        queryParameters: params,
      );

      final List<dynamic> content = response.data['content'];

      return content
          .map((json) {
            try {
              final fixedJson = Map<String, dynamic>.from(json);

              if (fixedJson['fechaVencimiento'] is int) {
                fixedJson['fechaVencimiento'] =
                    DateTime.fromMillisecondsSinceEpoch(
                  fixedJson['fechaVencimiento'],
                ).toIso8601String();
              }
              if (fixedJson['fechaEmisionDate'] is int) {
                fixedJson['fechaEmisionDate'] =
                    DateTime.fromMillisecondsSinceEpoch(
                  fixedJson['fechaEmisionDate'],
                ).toIso8601String();
              }

              return AccountsReceivable.fromJson(fixedJson);
            } catch (e) {
              return null;
            }
          })
          .whereType<AccountsReceivable>()
          .toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final message = (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<AccountsReceivableTotalResponse>> getTotales(
    Map<String, dynamic> params,
    List<Currency> currencies,
  ) async {
    final results = await Future.wait(currencies.map((currency) async {
      try {
        final response = await dio.get(
          '/accounts-receivable/operations/totales',
          queryParameters: {
            ...params,
            'codigoMoneda': currency.codigoMoneda,
          },
        );
        return AccountsReceivableTotalResponse.fromJson(response.data);
      } catch (_) {
        return null;
      }
    }));

    return results.whereType<AccountsReceivableTotalResponse>().toList();
  }

  @override
  Future<List<AccountsReceivableDetail>> getDetails(int id) async {
    try {
      final response = await dio.get(
        '/accounts-receivable-detail',
        queryParameters: {'id': id},
      );
      final List<dynamic> data = response.data;
      return data
          .map((json) => AccountsReceivableDetail.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final resData = e.response?.data;
      final message = (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await dio.put('/accounts-receivable/operations/cancel/$id');
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final resData = e.response?.data;
      final message = (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<void> extend(int id, int dias) async {
    try {
      await dio.put(
        '/accounts-receivable/operations/extend/$id',
        queryParameters: {'dias': dias},
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final resData = e.response?.data;
      final message = (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
