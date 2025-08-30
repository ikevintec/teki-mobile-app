import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/image.dart';
import 'package:teki_app/src/domain/datasource/image_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteImage extends ImageDatasource {
  Dio dio = ApiClient.dio;

  @override
  Future<ImageResponse> getImageUrl(
      int idCompany, String path, String filename) async {
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        path,
        filename: filename,
      ),
    });
    try {
      final response = await dio.post(
        '/files/companies/$idCompany/imagenes',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return ImageResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response != null) {
        return Future.error(e.response?.data['message']);
      } else {
        return Future.error(e.message ?? 'Error de conexión');
      }
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
