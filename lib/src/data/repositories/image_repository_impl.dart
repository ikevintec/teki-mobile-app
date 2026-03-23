

import 'package:teki_app/src/data/datasource/remote_image.dart';
import 'package:teki_app/src/data/models/response/image.dart';
import 'package:teki_app/src/domain/datasource/image_datasource.dart';
import 'package:teki_app/src/domain/repositories/image_repository.dart';

class ImageRepositoryImpl extends ImageRepository {
  ImageDatasource imageDatasource;
  ImageRepositoryImpl({ImageDatasource? imageDatasource})
      : imageDatasource = imageDatasource ?? RemoteImage();

  @override
  Future<ImageResponse> getImageUrl(int idCompany, String path, String filename) {
    return imageDatasource.getImageUrl(idCompany, path, filename);
  }
}