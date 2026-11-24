import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/data/models/response/image.dart';
import 'package:teki_app/src/data/repositories/image_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/image_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';

final imageProvider = StateNotifierProvider<ImageNotifier, ImageState>(
  (ref) {
    ImageRepository imageRepository = ImageRepositoryImpl();
    return ImageNotifier(imageRepository: imageRepository, ref: ref);
  },
);

class ImageNotifier extends StateNotifier<ImageState> {
  final ImageRepository imageRepository;
  final Ref ref;
  ImageNotifier({required this.imageRepository, required this.ref})
      : super(ImageState(url: ''));

  Future<String> getImage(XFile file) async {
    try {
      int idCompany = ref.read(sesionProvider).company?.id ?? 0;
      ImageResponse response =
          await imageRepository.getImageUrl(idCompany, file.path, file.name);
      String url = response.url;
      state = state.copyWith(url: url);
      return url;
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  void setImage(String url) {
    state = state.copyWith(url: url);
  }

  void clearImage() {
    state = state.copyWith(url: '');
  }
}

class ImageState {
  final String? url;

  ImageState({required this.url});
  ImageState copyWith({String? url}) {
    return ImageState(
      url: url ?? this.url,
    );
  }
}
