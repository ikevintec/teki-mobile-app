import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:teki_app/main.dart';
import 'navigation/dashboard_navigation.dart';
import 'navigation/dashboard_bottom_bar.dart';
import 'package:teki_app/src/presentation/screens/customer/customer_main_screen.dart';
import 'package:teki_app/src/presentation/screens/ai_chat/ai_chat_screen.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/header_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja_tab.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/inicio_tab.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/inventario_tab.dart';
import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:teki_app/src/providers/config/config.dart';

class DashboardMainScreen extends ConsumerStatefulWidget {
  const DashboardMainScreen({super.key});

  @override
  ConsumerState<DashboardMainScreen> createState() =>
      _DashboardMainScreenState();
}

class _DashboardMainScreenState extends ConsumerState<DashboardMainScreen>
    with RouteAware {
  final _sidebarController = SidebarXController(
    selectedIndex: 0,
    extended: true,
  );
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedTab = 0;

  /// Tabs que ya han sido visitados al menos una vez.
  /// Solo se monta el widget real del tab cuando se visita por primera vez.
  final _visitedTabs = <int>{0};

  /// Un notifier por tab para disparar recargas aisladas sin recrear widgets.
  final _refreshNotifiers = [
    ValueNotifier<int>(0),
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
    _sidebarController.dispose();
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
    if (!dashboardDestinations(
      ref.read(sesionProvider),
    ).any((destination) => destination.index == index)) {
      return;
    }
    if (_selectedTab == index) return;
    // Los tabs viven en un IndexedStack (no se recrean al cambiar): al volver
    // a un tab ya visitado sus datos pueden estar viejos — p.ej. regresar a
    // Inicio después de aperturar la caja en el tab Caja. Se recarga el tab
    // de destino, salvo en su primera visita (ahí ya carga al montarse).
    final yaVisitado = _visitedTabs.contains(index);
    setState(() {
      _selectedTab = index;
      _visitedTabs.add(index);
    });
    if (yaVisitado) {
      _refreshNotifiers[index].value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(sesionProvider);
    final idPuntoVenta = config.office?.id ?? 0;
    final destinations = dashboardDestinations(config);
    final allowedIndices = destinations.map((d) => d.index).toSet();

    ref.listen<SesionState>(sesionProvider, (prev, next) {
      final allowed = dashboardDestinations(next).map((d) => d.index).toSet();
      if (!allowed.contains(_selectedTab)) _selectedTab = 0;
      _visitedTabs.removeWhere((index) => !allowed.contains(index));
      if (prev?.office?.id != next.office?.id ||
          prev?.companySelected?.id != next.companySelected?.id) {
        // Inventario recibe el id nuevo directamente como propiedad y se
        // recarga en didUpdateWidget. Inicio y Caja usan sus notifiers.
        _refreshNotifiers[0].value++;
        _refreshNotifiers[3].value++;
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      drawer: DashboardDrawer(
        routeName: 'Dashboard',
        controller: _sidebarController,
      ),
      backgroundColor: const Color.fromARGB(255, 246, 248, 255),
      // Usamos extendBody para que el contenido llegue hasta el borde inferior
      // detrás del navbar flotante.
      extendBody: true,
      body: Column(
        children: [
          // ── Header fijo con gradiente ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 14, 78, 210),
                  Color.fromARGB(255, 56, 152, 236),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Círculo decorativo superior derecho
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                // Círculo decorativo inferior izquierdo
                Positioned(
                  bottom: 10,
                  left: -40,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                // Círculo decorativo medio
                Positioned(
                  top: 10,
                  right: 90,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Contenido del header
                SafeArea(
                  bottom: false,
                  child: DashboardHeaderSection(
                    openDrawer: () {
                      if (!Platform.isAndroid && !Platform.isIOS) {
                        _sidebarController.setExtended(true);
                      }
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    // El orbe del asistente vive en el header, visible en
                    // todos los tabs del dashboard.
                    onAiTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiChatScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Área de contenido ─────────────────────────────────────────
          Expanded(
            child: _FadeIndexedStack(
              index: _selectedTab,
              visitedIndices: _visitedTabs.intersection(allowedIndices),
              children: [
                InicioTab(
                  idPuntoVenta: idPuntoVenta,
                  refreshNotifier: _refreshNotifiers[0],

                  onIrACaja: () => _onTabSelected(3),
                  onIrAClientes: () => _onTabSelected(1),
                  onIrAInventario: () => _onTabSelected(2),
                ),
                CustomerMainScreen(
                  key: ValueKey((config.companySelected?.id, config.login)),
                  embedded: true,
                  refreshNotifier: _refreshNotifiers[1],
                ),
                InventarioTab(
                  idPuntoVenta: idPuntoVenta,
                  refreshNotifier: _refreshNotifiers[2],
                ),
                CajaTab(refreshNotifier: _refreshNotifiers[3]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomBar(
        destinations: destinations,
        selected: DashboardDestination.values[_selectedTab],
        onSelected: (destination) => _onTabSelected(destination.index),
      ),
    );
  }
}

class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final Set<int> visitedIndices;
  final List<Widget> children;

  const _FadeIndexedStack({
    required this.index,
    required this.visitedIndices,
    required this.children,
  });

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
        // Solo monta el widget real si el tab ya fue visitado.
        // La primera vez que se selecciona un tab, se agrega a visitedIndices
        // y se monta su widget (ejecutando initState y cargando datos).
        // En visitas posteriores el widget ya está montado y no se recarga.
        final child = widget.visitedIndices.contains(i)
            ? widget.children[i]
            : const SizedBox.shrink();
        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: child,
          ),
        );
      }),
    );
  }
}
