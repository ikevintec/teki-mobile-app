import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teki_app/src/shared/services/internet_monitor.dart';

/// Franja persistente, fuera del navegador: acompaña al usuario en toda la app.
class InternetBanner extends StatefulWidget {
  const InternetBanner({super.key, required this.child, this.monitor});

  final Widget child;
  final InternetMonitor? monitor;

  @override
  State<InternetBanner> createState() => _InternetBannerState();
}

class _InternetBannerState extends State<InternetBanner>
    with WidgetsBindingObserver {
  late final InternetMonitor _monitor;
  // Estilo de reserva del encabezado azul; los AppBar/AnnotatedRegion de
  // cada pantalla conservan prioridad sobre esta región exterior.
  static const _fallbackStatusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    _monitor = widget.monitor ?? InternetMonitor.instance;
    WidgetsBinding.instance.addObserver(this);
    _monitor.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _monitor.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _monitor.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitor.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _fallbackStatusBarStyle,
      child: ValueListenableBuilder<InternetState>(
        valueListenable: _monitor,
        builder: (context, state, _) => Column(
          children: [
            if (state == InternetState.disconnected)
              Semantics(
                liveRegion: true,
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarBrightness: Brightness.light,
                    statusBarIconBrightness: Brightness.dark,
                  ),
                  child: Material(
                    color: const Color(0xFFFFF3CD),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 18,
                              color: Color(0xFF664D03),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Sin conexión a Internet',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF664D03),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: state == InternetState.disconnected,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
