import 'package:teki_app/src/data/models/teki_model/loyalty_coupon.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_page.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_points_movement.dart';
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/domain/datasource/loyalty_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteLoyalty implements LoyaltyDatasource {
  final Dio dio;
  RemoteLoyalty({Dio? dio}) : dio = dio ?? ApiClient.dio;

  static const path = '/loyalty/config/cards';

  @override
  Future<List<LoyaltyCard>> getCards({CancelToken? cancelToken}) async {
    try {
      final response = await dio.get<List<dynamic>>(
        path,
        cancelToken: cancelToken,
      );
      return (response.data ?? [])
          .map((json) => LoyaltyCard.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<LoyaltyCard> getCard(int id, {CancelToken? cancelToken}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '$path/$id',
        cancelToken: cancelToken,
      );
      return LoyaltyCard.fromJson(response.data!);
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<LoyaltyPage<LoyaltyCustomer>> getCustomers(
    int cardId, {
    String filter = '',
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/loyalty/customers',
        queryParameters: {
          'idLoyaltyConfig': cardId,
          'pageNumber': page,
          'perPage': size,
          if (filter.trim().isNotEmpty) 'filtro': filter.trim(),
        },
        cancelToken: cancelToken,
      );
      return LoyaltyPage.fromJson(response.data!, LoyaltyCustomer.fromJson);
    } on DioException catch (error) {
      throw _translate(error, customers: true);
    }
  }

  @override
  Future<LoyaltyCustomer> getCustomer(
    int id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/loyalty/customers/$id',
        cancelToken: cancelToken,
      );
      return LoyaltyCustomer.fromJson(response.data!);
    } on DioException catch (error) {
      throw _translate(error, customers: true);
    }
  }

  @override
  Future<LoyaltyPage<LoyaltyPointsMovement>> getMovements(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/loyalty/customers/$enrollmentId/movimientos',
        queryParameters: {'pageNumber': page, 'perPage': size},
        cancelToken: cancelToken,
      );
      return LoyaltyPage.fromJson(
        response.data!,
        LoyaltyPointsMovement.fromJson,
      );
    } on DioException catch (error) {
      throw _translate(error, customers: true);
    }
  }

  @override
  Future<LoyaltyPage<LoyaltyCoupon>> getCoupons(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/loyalty/coupons',
        queryParameters: {
          'idLoyaltyCustomer': enrollmentId,
          'esGlobal': false,
          'pageNumber': page,
          'perPage': size,
        },
        cancelToken: cancelToken,
      );
      return LoyaltyPage.fromJson(response.data!, LoyaltyCoupon.fromJson);
    } on DioException catch (error) {
      throw _translate(error, customers: true);
    }
  }

  Exception _translate(DioException error, {bool customers = false}) {
    if (CancelToken.isCancel(error)) return error;
    if (error.response?.statusCode == 403) {
      return Exception(
        customers
            ? 'No tienes acceso a los clientes de esta empresa.'
            : 'No tienes acceso a las tarjetas de esta empresa.',
      );
    }
    if (error.response?.statusCode == 404) {
      return Exception(
        customers
            ? 'La inscripción ya no está disponible.'
            : 'La tarjeta ya no está disponible.',
      );
    }
    if (error.message == 'SESSION_EXPIRED' ||
        error.response?.statusCode == 401) {
      return Exception('Tu sesión ha expirado. Vuelve a iniciar sesión.');
    }
    return Exception(
      error.response == null
          ? 'Sin conexión. Comprueba tu internet y vuelve a intentar.'
          : customers
          ? 'No se pudo cargar la información de fidelización. Vuelve a intentar.'
          : 'No se pudieron cargar las tarjetas. Vuelve a intentar.',
    );
  }
}
