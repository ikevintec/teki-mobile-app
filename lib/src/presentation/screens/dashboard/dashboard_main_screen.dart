import 'dart:io';
import 'dart:ui';
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
                child: _FadeIndexedStack(
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 48, 47, 103).withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 9),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(32),
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
        ),
      ),
    );
  }
}

class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({required this.index, required this.children});

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final isActive = i == widget.index;
        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: widget.children[i],
          ),
        );
      }),
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
            constraints: const BoxConstraints(minWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorSchema.primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected
                      ? ColorSchema.primaryColor
                      : const Color.fromARGB(255, 129, 129, 129),
                ),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? ColorSchema.primaryColor
                        : const Color.fromARGB(255, 129, 129, 129),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
