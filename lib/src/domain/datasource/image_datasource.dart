import 'package:teki_app/src/data/models/response/image.dart';

abstract class ImageDatasource {
  Future<ImageResponse> getImageUrl(int idCompany, String path, String filename);
}