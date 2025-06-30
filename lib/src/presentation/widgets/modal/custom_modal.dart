import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

void showCustomModal(BuildContext context, Widget child, String tittle,
    [bool allowButtons = true]) {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showScrollHint = ValueNotifier(false);

  void _updateScrollHint() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    _showScrollHint.value = currentScroll < maxScroll;
  }

  _scrollController.addListener(_updateScrollHint);

  WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());

  showGeneralDialog(
    barrierDismissible: allowButtons,
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
              child: SizedBox(
                width: double.maxFinite,
                height: 550,
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      tittle,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: child,
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: _showScrollHint,
                            builder: (context, show, _) {
                              return show
                                  ? Positioned(
                                      bottom: 10,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            final maxScroll = _scrollController
                                                .position.maxScrollExtent;
                                            final current = _scrollController
                                                .position.pixels;
                                            final next = (current + 100)
                                                .clamp(0, maxScroll)
                                                .toDouble();

                                            _scrollController.animateTo(
                                              next,
                                              duration: const Duration(
                                                  milliseconds: 300),
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
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 25, right: 10, top: 2, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorSchema.primaryColor,
                            ),
                            child: const Text("Volver",
                                style: TextStyle(color: Colors.white)),
                          ),
                          if (allowButtons) const SizedBox(width: 20),
                          if (allowButtons)
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorSchema.primaryColor,
                              ),
                              child: const Text("Aceptar",
                                  style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
