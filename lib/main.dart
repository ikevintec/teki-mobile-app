import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/application.dart';
import 'package:teki_app/src/providers/login.dart';
import 'package:teki_app/src/utils/contstants.dart';

final ProviderContainer globalContainer = ProviderContainer();
void main() async{
  await Environment.intiEnvironment();
  await globalContainer.read(authStateProvider.notifier).checkAuthStatus();
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
