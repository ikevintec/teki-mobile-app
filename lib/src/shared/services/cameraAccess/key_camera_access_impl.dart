import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/shared/services/cameraAccess/key_camera_access.dart';

class KeyCameraAccessImpl implements KeyCameraAccess {
  final ImagePicker picker = ImagePicker();

  @override
  Future<XFile?> getFromCamera() async {
    final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear);
    return image;
  }

  @override
  Future<XFile?> getFromGallery() async {
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    return image;
  }
}
