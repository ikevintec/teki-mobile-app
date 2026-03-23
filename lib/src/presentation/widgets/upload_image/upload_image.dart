import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/shared/services/cameraAccess/key_camera_access_impl.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class UploadImage extends ConsumerWidget {
  final String image;
  final bool? showButtons;
  final void Function(String newImage, XFile? file)? onImageSelected;
  const UploadImage(
      {super.key,
      required this.image,
      this.onImageSelected,
      this.showButtons = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int sizeLimit = 1;
    KeyCameraAccessImpl keyCameraAccess = KeyCameraAccessImpl();
    return Align(
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Container(
              width: 180,
              height: 180,
              color: const Color.fromARGB(255, 245, 245, 245),
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
                                  child: CircularProgressIndicator(),
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/products/icon.png',
                              fit: BoxFit.contain,
                            ),
            ),
          ),
          if (showButtons!)
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
                    if (onImageSelected != null) {
                      onImageSelected!(file.path, file);
                    }
                  },
                  child: CircleAvatar(
                      radius: 20,
                      backgroundColor: ColorSchema.primaryColor,
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 17,
                      )),
                )),
          if (showButtons!)
            Positioned(
                right: -25,
                bottom: 88,
                child: GestureDetector(
                  onTap: () async {
                    print('Seleccion de imagen de galeria');
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
                    if (onImageSelected != null) {
                      onImageSelected!(file.path, file);
                    }
                  },
                  child: CircleAvatar(
                      radius: 20,
                      backgroundColor: ColorSchema.primaryColor,
                      child: Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 17,
                      )),
                )),
          //Boton para eliminar imagen si esque se selecciona una
          if (image.isNotEmpty && showButtons!)
            Positioned(
              left: 15,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  if (onImageSelected != null) {
                    onImageSelected!("", null);
                  }
                },
                child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 15,
                    )),
              ),
            )
        ],
      ),
    );
  }
}
