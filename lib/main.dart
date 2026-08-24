import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teki_app/src/application.dart';
import 'package:teki_app/src/shared/services/yape_sync_controller.dart';
import 'package:teki_app/src/utils/constants.dart';
// Nota: firebase_options.dart se genera con `flutterfire configure`.
// Cuando lo ejecutes, descomenta la línea de abajo y usa DefaultFirebaseOptions.currentPlatform.
// import 'package:teki_app/firebase_options.dart';

final ProviderContainer globalContainer = ProviderContainer();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// Handler de background: debe ser top-level, no puede usar contexto ni navegar.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message recibido: ${message.messageId}');
  // Procesar solo data silenciosa aquí si es necesario.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Environment.initEnvironment();
  await initializeDateFormatting('es', null);
  runApp(
    UncontrolledProviderScope(
      container: globalContainer,
      child: const ProviderScope(child: MyApp()),
    ),
  );
  // Registra los Yapes capturados por el nativo mientras la app esté viva.
  YapeSyncController.instance.start(globalContainer);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Application();
  }
}
