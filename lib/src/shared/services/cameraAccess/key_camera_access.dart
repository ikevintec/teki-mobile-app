import 'package:image_picker/image_picker.dart';

abstract class KeyCameraAccess {
  /// The key used to access the camera.
  Future<XFile?> getFromCamera();
  Future<XFile?> getFromGallery();
}
