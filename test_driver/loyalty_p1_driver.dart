import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final directory =
        Platform.environment['LOYALTY_QA_OUTPUT'] ?? '/tmp/teki-loyalty-qa';
    final output = File('$directory/$name.png');
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes);
    return true;
  },
);
