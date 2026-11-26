import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

final directCheckoutServiceProvider = Provider(
  (ref) => DirectCheckoutService(),
);

class DirectCheckoutResult {
  final OrderRestaurant order;
  final Check check;
  final bool replayed;
  final String action;
  final bool automaticPrinting;
  final Map<String, dynamic> checkoutData;
  const DirectCheckoutResult(
    this.order,
    this.check,
    this.replayed,
    this.action, {
    this.automaticPrinting = true,
    this.checkoutData = const {},
  });
}

/// Uses the same endpoint and invoice builder as the web. No fiscal calculation
/// or independent order/check save belongs in the mobile client.
class DirectCheckoutService {
  final Dio dio;
  DirectCheckoutService({Dio? dio}) : dio = dio ?? ApiClient.dio;
  static const endpoint = '/orders-restaurant/direct-checkout';

  Future<Map<String, dynamic>> preview(Map<String, dynamic> request) async =>
      Map<String, dynamic>.from(
        (await dio.post('$endpoint/preview', data: request)).data,
      );

  Future<DirectCheckoutResult> submit(Map<String, dynamic> request) async {
    final data = (await dio.post(endpoint, data: request)).data;
    // An incomplete success is uncertain, never grounds to generate a new UUID.
    if (data is! Map ||
        data['pedido']?['id'] == null ||
        data['cuenta']?['id'] == null ||
        request['action'] == 'INVOICE' &&
            data['cuenta']?['comprobante']?['id'] == null) {
      throw StateError(
        'No se recibió la confirmación completa. Recupere el pedido.',
      );
    }
    return DirectCheckoutResult(
      OrderRestaurant.fromJson(data['pedido']),
      Check.fromJson(data['cuenta']),
      data['replayed'] == true,
      request['action'],
      checkoutData: Map<String, dynamic>.from(jsonDecode(jsonEncode(request))),
    );
  }

  Future<List<String>> series(int office, String type) async {
    final data =
        (await dio.get(
              '/series/office/$office',
              queryParameters: {'tipoDocumento': type},
            )).data
            as List;
    return data
        .map((s) => s['numero']?.toString())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> users() async =>
      ((await dio.get('/users/all')).data as List)
          .map((u) => Map<String, dynamic>.from(u))
          .toList();

  Future<Map<String, dynamic>?> pending(String scope) async {
    final value = (await SharedPreferences.getInstance()).getString(
      'restaurant-checkout:$scope',
    );
    return value == null ? null : Map<String, dynamic>.from(jsonDecode(value));
  }

  Future<void> remember(String scope, Map<String, dynamic> request) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      'restaurant-checkout:$scope',
      jsonEncode(request),
    )) {
      throw StateError(
        'No se pudo conservar el pedido para recuperarlo. Intente nuevamente.',
      );
    }
  }

  /// Claim before dispatch: absent means this installation never started printing.
  /// A matching marker is uncertain/completed paper, so recovery offers reprint.
  Future<bool> claimPrinting(String scope, String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'restaurant-checkout-printing:$scope';
    if (prefs.getString(key) == operationId) return false;
    if (!await prefs.setString(key, operationId)) {
      throw StateError('No se pudo registrar el intento de impresión.');
    }
    return true;
  }

  Future<void> forget(String scope) async {
    await (await SharedPreferences.getInstance()).remove(
      'restaurant-checkout:$scope',
    );
  }
}
