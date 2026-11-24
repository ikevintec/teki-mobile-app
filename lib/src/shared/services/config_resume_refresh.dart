import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/auth/login.dart';

/// Refresca una vez al regresar del fondo; una interrupción breve (inactive) no cuenta.
class ConfigResumeRefresh extends ConsumerStatefulWidget {
  final Widget child;
  const ConfigResumeRefresh({super.key, required this.child});

  @override
  ConsumerState<ConfigResumeRefresh> createState() =>
      _ConfigResumeRefreshState();
}

class _ConfigResumeRefreshState extends ConsumerState<ConfigResumeRefresh>
    with WidgetsBindingObserver {
  bool _background = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _background = true;
    } else if (state == AppLifecycleState.resumed && _background) {
      _background = false;
      unawaited(ref.read(authStateProvider.notifier).refreshConfigCompany());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
