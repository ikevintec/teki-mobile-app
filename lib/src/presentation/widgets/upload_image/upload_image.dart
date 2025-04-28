import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/shared/services/cameraAccess/key_camera_access_impl.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class UploadImage extends ConsumerWidget {
  final String image;
  final void Function(String newImage, XFile? file) onImageSelected;
  const UploadImage(
      {super.key, required this.image, required this.onImageSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int sizeLimit = 2;
    KeyCameraAccessImpl keyCameraAccess = KeyCameraAccessImpl();
    return Align(
      alignment: Alignment.center,
      child: Stack(
        children: [
          ClipOval(
            child: Container(
              width: 200,
              height: 200,
              color: Colors.grey.shade200,
              child: image.startsWith("assets/")
                  ? Image.asset(
                      image,
                      fit: BoxFit.contain,
                    )
                  : image.startsWith("/data/") || image.startsWith("/storage/")
                      ? Image.file(
                          File(image),
                          fit: BoxFit.contain,
                        )
                      : image.isNotEmpty
                          ? Image.network(
                              image,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/logo/icon.png',
                              fit: BoxFit.contain,
                            ),
            ),
          ),
          Positioned(
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  XFile? file = await keyCameraAccess.getFromCamera();
                  if (file == null) return;
                  int fileSizeInBytes = await file.length();
                  double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
                  print('File size camara: $fileSizeInMB MB');
                  if (fileSizeInMB > sizeLimit) {
                    errorNotification(
                        "El tamaño del archivo es mayor a ${sizeLimit}MB");
                    return;
                  }
                  onImageSelected(file.path, file);
                },
                child: CircleAvatar(
                    radius: 20,
                    backgroundColor: ColorSchema.primaryColor,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                    )),
              )),
          Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () async {
                  XFile? file = await keyCameraAccess.getFromGallery();
                  if (file == null) return;
                  int fileSizeInBytes = await file.length();
                  double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
                  print('File size galeria: $fileSizeInMB MB');

                  if (fileSizeInMB > sizeLimit) {
                    errorNotification(
                        "El tamaño de la imagen seleccionada es mayor a ${sizeLimit}MB");
                    return;
                  }
                  onImageSelected(file.path, file);
                },
                child: CircleAvatar(
                    radius: 20,
                    backgroundColor: ColorSchema.primaryColor,
                    child: Icon(
                      Icons.image,
                      color: Colors.white,
                    )),
              ))
        ],
      ),
    );
  }
}
