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

  Exception _translate(DioException error) {
    if (CancelToken.isCancel(error)) return error;
    if (error.response?.statusCode == 403) {
      return Exception('No tienes acceso a las tarjetas de esta empresa.');
    }
    if (error.response?.statusCode == 404) {
      return Exception('La tarjeta ya no está disponible.');
    }
    if (error.message == 'SESSION_EXPIRED' ||
        error.response?.statusCode == 401) {
      return Exception('Tu sesión ha expirado. Vuelve a iniciar sesión.');
    }
    return Exception(
      error.response == null
          ? 'Sin conexión. Comprueba tu internet y vuelve a intentar.'
          : 'No se pudieron cargar las tarjetas. Vuelve a intentar.',
    );
  }
}
