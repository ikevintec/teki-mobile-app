import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/header_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja_tab.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/inicio_tab.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/inventario_tab.dart';
import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';

class DashboardMainScreen extends ConsumerStatefulWidget {
  const DashboardMainScreen({super.key});

  @override
  ConsumerState<DashboardMainScreen> createState() =>
      _DashboardMainScreenState();
}

class _DashboardMainScreenState extends ConsumerState<DashboardMainScreen>
    with RouteAware {
  final _sidebarController =
      SidebarXController(selectedIndex: 0, extended: true);
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedTab = 0;

  /// Un notifier por tab para disparar recargas aisladas sin recrear widgets.
  final _refreshNotifiers = [
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    for (final n in _refreshNotifiers) {
      n.dispose();
    }
    super.dispose();
  }

  /// Cuando el usuario regresa al dashboard desde una sub-pantalla, solo
  /// recargamos el tab activo incrementando su notifier.
  @override
  void didPopNext() {
    _refreshNotifiers[_selectedTab].value++;
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(sesionProvider);
    final idPuntoVenta = config.office?.id ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: DashboardDrawer(
        routeName: 'Dashboard',
        controller: _sidebarController,
      ),
      backgroundColor: Colors.white,
      // Usamos extendBody para que el contenido llegue hasta el borde inferior
      // detrás del navbar flotante.
      extendBody: true,
      body: Column(
        children: [
          // ── Header fijo con gradiente ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(255, 19, 94, 232),
                  Colors.blue[400]!,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: DashboardHeaderSection(
                openDrawer: () {
                  if (!Platform.isAndroid && !Platform.isIOS) {
                    _sidebarController.setExtended(true);
                  }
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ),
          ),

          // ── Área de contenido (blanco, esquinas redondeadas) ───────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                // IndexedStack mantiene los 3 tabs vivos simultáneamente,
                // preservando estado (scroll, datos) al cambiar de tab.
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    InicioTab(
                      idPuntoVenta: idPuntoVenta,
                      refreshNotifier: _refreshNotifiers[0],
                    ),
                    InventarioTab(
                      refreshNotifier: _refreshNotifiers[1],
                    ),
                    CajaTab(
                      refreshNotifier: _refreshNotifiers[2],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  isSelected: _selectedTab == 0,
                  onTap: () => _onTabSelected(0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventario',
                  isSelected: _selectedTab == 1,
                  onTap: () => _onTabSelected(1),
                ),
                _NavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Caja',
                  isSelected: _selectedTab == 2,
                  onTap: () => _onTabSelected(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: isSelected
                ? const EdgeInsets.symmetric(horizontal: 18, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorSchema.primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 25,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey.shade400,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
