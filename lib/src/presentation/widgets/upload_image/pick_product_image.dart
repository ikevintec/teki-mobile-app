import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/shared/services/cameraAccess/key_camera_access_impl.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Muestra un menú (cámara / galería), valida el tamaño (máx. [sizeLimitMB] MB)
/// y devuelve el [XFile] seleccionado, o `null` si se cancela o excede el peso.
///
/// Centraliza la lógica que antes vivía duplicada dentro de `UploadImage`
/// para poder reutilizarla en la tira de miniaturas.
Future<XFile?> pickProductImage(
  BuildContext context, {
  double sizeLimitMB = 1,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined,
                color: ColorSchema.primaryColor),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading:
                const Icon(Icons.image, color: ColorSchema.primaryColor),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;

  final keyCameraAccess = KeyCameraAccessImpl();
  final XFile? file = source == ImageSource.camera
      ? await keyCameraAccess.getFromCamera()
      : await keyCameraAccess.getFromGallery();
  if (file == null) return null;

  final fileSizeInMB = (await file.length()) / (1024 * 1024);
  if (fileSizeInMB > sizeLimitMB) {
    errorNotification(
        "El tamaño de la imagen es mayor a ${sizeLimitMB.toStringAsFixed(0)}MB");
    return null;
  }

  return file;
}
