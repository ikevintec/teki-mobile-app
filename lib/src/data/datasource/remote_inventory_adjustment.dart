import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:teki_app/src/data/models/response/inventory_adjustment_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_adjustment.dart';
import 'package:teki_app/src/domain/datasource/inventory_adjustment_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteInventoryAdjustment extends InventoryAdjustmentDatasource {
  Dio dio = ApiClient.dio;

  @override
  Future<InventoryAdjustmentResponse> getAdjustments(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await dio.get(
        '/inventory-adjustment',
        queryParameters: params,
      );
      return InventoryAdjustmentResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final errorMessage =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      errorNotification(errorMessage);
      return InventoryAdjustmentResponse(
        content: [],
        empty: true,
        first: true,
        last: false,
        number: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
        sort: null,
        pageable: null,
      );
    } catch (e) {
      errorNotification(e.toString());
      return InventoryAdjustmentResponse(
        content: [],
        empty: true,
        first: true,
        last: false,
        number: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
        sort: null,
        pageable: null,
      );
    }
  }

  @override
  Future<InventoryAdjustment> saveAdjustment(
    InventoryAdjustment adjustment,
  ) async {
    try {
      final response = await dio.post(
        '/inventory-adjustment',
        data: adjustment.toJson(),
      );
      // El ajuste ya se registró: si la respuesta no se puede mapear (campos
      // nuevos, lotes, etc.) no debe reportarse como error al usuario.
      try {
        return InventoryAdjustment.fromJson(response.data);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('No se pudo mapear la respuesta del ajuste: $e');
        }
        return adjustment;
      }
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final errorMessage =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error al guardar ajuste';
      return Future.error(errorMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
