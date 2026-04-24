import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

Future<void> showCustomModal({
  required BuildContext context,
  required Widget child,
  required String tittle,
  bool allowButtons = true,
  bool showButtoms = true,
  bool scrolleable = true,
  bool autoSize = true,
  double? fixedHeight,
  bool showCloseButton = false,
}) {
  final size = MediaQuery.of(context).size;

  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> showScrollHint = ValueNotifier(false);

  void updateScrollHint() {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    showScrollHint.value = currentScroll < maxScroll;
  }

  scrollController.addListener(updateScrollHint);

  WidgetsBinding.instance.addPostFrameCallback((_) => updateScrollHint());

  FocusManager.instance.primaryFocus?.unfocus();

  return showGeneralDialog(
    barrierDismissible: allowButtons,
    barrierLabel: tittle,
    transitionDuration: const Duration(milliseconds: 200),
    context: context,
    pageBuilder: (context, anim1, anim2) {
      return Stack(
        children: [
          // Fondo desenfocado
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
          Center(
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: size.height * 0.9,
                    maxWidth: size.width * 0.9,
                    minWidth: size.width * 0.8,
                  ),
                  child: autoSize
                      ? IntrinsicHeight(
                          child: _buildModalContent(
                            context: context,
                            tittle: tittle,
                            child: child,
                            scrolleable: scrolleable,
                            showButtoms: showButtoms,
                            allowButtons: allowButtons,
                            scrollController: scrollController,
                            showScrollHint: showScrollHint,
                            size: size,
                            showCloseButton: showCloseButton,
                          ),
                        )
                      : SizedBox(
                          height: fixedHeight ?? size.height * 0.7,
                          child: _buildModalContent(
                            context: context,
                            tittle: tittle,
                            child: child,
                            scrolleable: scrolleable,
                            showButtoms: showButtoms,
                            allowButtons: allowButtons,
                            scrollController: scrollController,
                            showScrollHint: showScrollHint,
                            size: size,
                            showCloseButton: showCloseButton,
                          ),
                        ),
                );
              }),
            ),
          ),
        ],
      );
    },
  ).then((_) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  });
}

Widget _buildModalContent({
  required BuildContext context,
  required String tittle,
  required Widget child,
  required bool scrolleable,
  required bool showButtoms,
  required bool allowButtons,
  required ScrollController scrollController,
  required ValueNotifier<bool> showScrollHint,
  required Size size,
  bool showCloseButton = false,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (tittle.isNotEmpty) ...[
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              SizedBox(width: showCloseButton ? 30 : 0),
              Expanded(
                child: Text(
                  tittle,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (showCloseButton)
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.close, size: 22, color: Colors.black54),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
      if (!scrolleable)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: child,
        ),
      if (scrolleable)
        Flexible(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: child,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: showScrollHint,
                builder: (context, show, _) {
                  return show
                      ? Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                final maxScroll = scrollController.position.maxScrollExtent;
                                final current = scrollController.position.pixels;
                                final next = (current + 100).clamp(0, maxScroll).toDouble();

                                scrollController.animateTo(
                                  next,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              },
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: ColorSchema.primaryColor,
                                size: 28,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      if (showButtoms) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 25, right: 25, top: 2, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorSchema.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Volver",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              if (allowButtons) ...[
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorSchema.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Aceptar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}