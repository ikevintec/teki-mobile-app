import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/constants.dart';

class CustomAppBar extends StatelessWidget {
  final String navigateName;
  final String? navigateRoute;
  final String? subtitle;
  final Color? backgroundColor;

  /// Acciones adicionales que se insertan antes del botón de ajustes.
  final List<Widget>? actions;

  /// Callback invocado al regresar de la pantalla de ajustes.
  final VoidCallback? onSettingsReturn;

  const CustomAppBar({
    super.key,
    required this.navigateName,
    this.navigateRoute,
    this.subtitle,
    this.backgroundColor,
    this.actions,
    this.onSettingsReturn,
  });

  /// Mismo estilo de título que pedidos (titleLarge, peso 500), para que venta,
  /// cotización y pedido se vean de la misma familia.
  TextStyle? _estiloTitulo(BuildContext context) => Theme.of(context)
      .textTheme
      .titleLarge
      ?.copyWith(fontWeight: FontWeight.w500, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: backgroundColor ?? ColorSchema.primaryColor,
      centerTitle: true,
      actions: [
        if (actions != null) ...actions!,
        IconButton(
          tooltip: 'Ajustes',
          onPressed: () async {
            await Get.toNamed(AppRoutes.settings);
            onSettingsReturn?.call();
          },
          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
        ),
      ],
      title: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  navigateName,
                  style: _estiloTitulo(context),
                ),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            )
          : Text(navigateName, style: _estiloTitulo(context)),
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: () {
          if (navigateRoute == null) {
            Get.back();
            return;
          }
          Get.offAllNamed(navigateRoute!);
        },
        icon: const Icon(
          color: Colors.white,
          Icons.chevron_left,
          size: 30,
        ),
      ),
    );
  }
}
