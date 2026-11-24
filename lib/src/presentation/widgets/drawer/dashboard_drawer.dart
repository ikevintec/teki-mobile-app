import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/data/models/route_item_model/dashboar_route_model.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:sidebarx/sidebarx.dart';

class DashboardDrawer extends ConsumerStatefulWidget {
  final String routeName;
  final SidebarXController controller;

  const DashboardDrawer(
      {super.key, required this.routeName, required this.controller});

  @override
  ConsumerState<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends ConsumerState<DashboardDrawer> {
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    List<Map<String, dynamic>> defaultRoutes = [
      {
        'icon': "assets/icons/icon_svg/settings.svg",
        'label': 'Configuracion',
        'route': AppRoutes.settings
      },
      {
        'icon': "assets/icons/icon_svg/log-out.svg",
        'label': 'Cerrar sesion',
        'route': AppRoutes.login
      }
    ];
    // Purga de plantilla: el único menú real es el del Dashboard; los casos
    // por módulo (Reports/Trading/Invoice/etc.) eran pantallas demo.
    items = [
      ...DashboardRouteModel,
      ...defaultRoutes,
    ];

    final initialIndex = items.indexWhere((item) => item['route']
        .toString()
        .toLowerCase()
        .contains(widget.routeName.toLowerCase()));
    if (initialIndex != -1) {
      widget.controller.selectIndex(initialIndex);
    } else {
      widget.controller.selectIndex(0); // por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = globalContainer.read(authStateProvider).user;
    String name = user?.name ?? "";
    String cargo = user?.cargo ?? "";
    String username = user?.username ?? "";
    String? avatarUrl = user?.avatarUrl;
    return SidebarX(
      controller: widget.controller,
      theme: SidebarXTheme(
        selectedItemPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        textStyle: GoogleFonts.roboto(
            textStyle: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 17,
                fontWeight: FontWeight.w500)),
        selectedTextStyle: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
            fontWeight: FontWeight.w600),
        itemTextPadding: const EdgeInsets.only(left: 10),
        selectedItemTextPadding: const EdgeInsets.only(left: 10),
        selectedItemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Colors.blue.shade50),
        iconTheme: IconThemeData(
          color: Colors.black.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
      extendedTheme: const SidebarXTheme(
          width: 300, padding: EdgeInsets.symmetric(horizontal: 15)),
      showToggleButton: false,
      headerBuilder: (context, extended) {
        if (widget.routeName == "Dashboard") {
          return Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              avatarUrl == null
                  ? Image.asset("assets/images/avatar/user_profile.png")
                  : ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error);
                        },
                      ),
                    ),
              const SizedBox(
                height: 10,
              ),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
              ),
              Text(
                username,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    textStyle: const TextStyle(color: Colors.black)),
              ),
              Text(
                cargo,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    textStyle: const TextStyle(color: Colors.grey)),
              ),
            ],
          );
        } else {
          return const SizedBox(
            height: 20,
          );
        }
      },
      items: items.map((item) {
        return SidebarXItem(
          iconBuilder: (context, selected) {
            return SvgPicture.asset(
              item['icon'],
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF333333),
                BlendMode.srcIn,
              ),
            );
          },
          label: item['label'],
          onTap: () {
            Navigator.pop(context);
            if (item['label'] == 'Cerrar sesion') {
              globalContainer.read(authStateProvider.notifier).logout();
              return;
            }
            Get.toNamed(item['route']);
          },
        );
      }).toList(),
    );
  }
}
