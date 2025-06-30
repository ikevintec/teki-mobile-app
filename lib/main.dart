import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/application.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:intl/date_symbol_data_local.dart';


final ProviderContainer globalContainer = ProviderContainer();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  await Environment.intiEnvironment();
  await initializeDateFormatting('es', null); 
  runApp(
    UncontrolledProviderScope(
      container: globalContainer,
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Application();
  }
}
