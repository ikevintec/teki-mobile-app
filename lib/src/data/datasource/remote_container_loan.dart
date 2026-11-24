import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/domain/datasource/container_loan_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteContainerLoan extends ContainerLoanDatasource {
  final Dio dio;

  RemoteContainerLoan({Dio? dio}) : dio = dio ?? ApiClient.dio;

  static const _path = '/container-loans';

  @override
  Future<(List<ContainerLoan>, int)> getLoans({
    int? customerId,
    int? officeId,
    required bool pending,
    required int page,
    required int size,
  }) async {
    try {
      final response = await dio.get(
        _path,
        queryParameters: {
          if (customerId != null) 'customerId': customerId,
          if (officeId != null) 'officeId': officeId,
          'pending': pending,
          'page': page,
          'size': size,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final content = (data['content'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ContainerLoan.fromJson)
          .toList();
      return (
        content,
        (data['totalElements'] as num?)?.toInt() ?? content.length,
      );
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, 'No se pudieron cargar los préstamos'),
      );
    }
  }

  @override
  Future<List<ContainerLoanTotal>> getTotals({
    int? customerId,
    int? officeId,
  }) async {
    try {
      final response = await dio.get(
        '$_path/totals',
        queryParameters: {
          if (customerId != null) 'customerId': customerId,
          if (officeId != null) 'officeId': officeId,
        },
      );
      return (response.data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ContainerLoanTotal.fromJson)
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, 'No se pudieron cargar los totales'),
      );
    }
  }

  @override
  Future<List<ContainerReturn>> getReturns(int loanId) async {
    try {
      final response = await dio.get('$_path/$loanId/returns');
      return (response.data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ContainerReturn.fromJson)
          .toList();
    } on DioException catch (error) {
      throw Exception(_errorMessage(error, 'No se pudo cargar el historial'));
    }
  }

  @override
  Future<ContainerLoan> receive(int loanId, ContainerReturn request) async {
    try {
      final response = await dio.post(
        '$_path/$loanId/returns',
        data: request.toJson(),
      );
      return ContainerLoan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(
          error,
          'No se pudo confirmar. Reintenta: la solicitud conserva su identificador.',
        ),
      );
    }
  }

  @override
  Future<ContainerLoan> reverse(int loanId, int returnId) async {
    try {
      final response = await dio.post(
        '$_path/$loanId/returns/$returnId/reverse',
        data: {},
      );
      return ContainerLoan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(
          error,
          'Comprueba que los envases sigan disponibles en esa sede.',
        ),
      );
    }
  }

  @override
  Future<List<ContainerOpeningProduct>> getOpeningProducts(String term) async {
    try {
      final response = await dio.get(
        '$_path/opening-products',
        queryParameters: {'term': term},
      );
      return (response.data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ContainerOpeningProduct.fromJson)
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, 'No se pudieron buscar los productos'),
      );
    }
  }

  @override
  Future<ContainerLoan> registerOpening(ContainerOpening request) async {
    try {
      final response = await dio.post('$_path/opening', data: request.toJson());
      return ContainerLoan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(
          error,
          'No se pudo confirmar. Reintenta con los mismos datos para evitar duplicados.',
        ),
      );
    }
  }

  @override
  Future<ContainerLoan> cancelOpening(int loanId) async {
    try {
      final response = await dio.post(
        '$_path/$loanId/cancel-opening',
        data: {},
      );
      return ContainerLoan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(
          error,
          'Revierta las devoluciones antes de anular la carga.',
        ),
      );
    }
  }

  String _errorMessage(DioException error, String fallback) {
    if (error.message == 'SESSION_EXPIRED') return 'Sesión expirada';
    if (error.response == null) return 'Sin conexión a internet';
    final data = error.response?.data;
    if (data is Map) {
      final message = data['mensaje'] ?? data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return fallback;
  }
}
