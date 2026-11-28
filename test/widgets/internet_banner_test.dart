import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/presentation/widgets/connectivity/internet_banner.dart';
import 'package:teki_app/src/shared/services/internet_monitor.dart';

void main() {
  testWidgets(
    'restaura barra previa aunque la pantalla no declare su propio estilo',
    (tester) async {
      tester.view.padding = const FakeViewPadding(top: 62);
      tester.view.viewPadding = const FakeViewPadding(top: 62);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      await tester.idle();
      var connected = false;
      final monitor = InternetMonitor(check: () async => connected);
      addTearDown(monitor.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              InternetBanner(monitor: monitor, child: child!),
          home: const Scaffold(body: Text('Inicio')),
        ),
      );
      await tester.pump();
      await tester.idle();
      expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.light);
      connected = true;
      await monitor.refresh();
      await tester.pump();
      await tester.idle();
      expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.dark);
      expect(
        SystemChrome.latestStyle?.statusBarIconBrightness,
        Brightness.light,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'barra nativa oscura sobre franja clara y restaura estilo al reconectar',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 62);
      tester.view.viewPadding = const FakeViewPadding(top: 62);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      var connected = true;
      final monitor = InternetMonitor(check: () async => connected);
      addTearDown(monitor.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              InternetBanner(monitor: monitor, child: child!),
          home: const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: Colors.blue,
              body: SafeArea(child: Text('Inicio')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.idle();
      expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.dark);
      connected = false;
      await monitor.refresh();
      await tester.pump();
      await tester.idle();
      expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.light);
      expect(
        SystemChrome.latestStyle?.statusBarIconBrightness,
        Brightness.dark,
      );
      expect(
        tester.getTopLeft(find.text('Sin conexión a Internet')).dy,
        greaterThanOrEqualTo(62),
      );
      connected = true;
      await monitor.refresh();
      await tester.pump();
      await tester.idle();
      expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.dark);
      expect(find.text('Sin conexión a Internet'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'franja persistente sin tapar formulario, conserva texto y foco al reconectar',
    (tester) async {
      var connected = true;
      final monitor = InternetMonitor(check: () async => connected);
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(() {
        monitor.dispose();
        controller.dispose();
        focus.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              InternetBanner(monitor: monitor, child: child!),
          home: Scaffold(
            body: SafeArea(
              child: TextField(controller: controller, focusNode: focus),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Sin conexión a Internet'), findsNothing);
      final originalField = tester.state(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'correo@ejemplo.test');
      focus.requestFocus();
      connected = false;
      await monitor.refresh();
      await tester.pump();
      expect(find.text('Sin conexión a Internet'), findsOneWidget);
      expect(tester.state(find.byType(TextField)), same(originalField));
      expect(
        tester.getBottomLeft(find.text('Sin conexión a Internet')).dy,
        lessThan(tester.getTopLeft(find.byType(TextField)).dy),
      );
      expect(focus.hasFocus, isTrue);
      connected = true;
      await monitor.refresh();
      await tester.pump();
      expect(find.text('Sin conexión a Internet'), findsNothing);
      expect(tester.state(find.byType(TextField)), same(originalField));
      expect(controller.text, 'correo@ejemplo.test');
      expect(focus.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'texto grande en celular angosto sin desbordamiento y con aviso accesible',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final monitor = InternetMonitor(check: () async => false);
      addTearDown(monitor.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: InternetBanner(monitor: monitor, child: child!),
          ),
          home: const Scaffold(body: Text('Formulario')),
        ),
      );
      await tester.pump();
      expect(find.text('Sin conexión a Internet'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      expect(
        semantics.any((widget) => widget.properties.liveRegion == true),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
