import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/shared/services/key_values_storage_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyValueStorageServiceImpl storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = KeyValueStorageServiceImpl();
  });

  group('KeyValueStorageServiceImpl', () {
    test('guarda y lee String', () async {
      await storage.setKeyValue<String>('k', 'valor');
      expect(await storage.getValue<String>('k'), 'valor');
    });

    test('guarda y lee int', () async {
      await storage.setKeyValue<int>('k', 42);
      expect(await storage.getValue<int>('k'), 42);
    });

    test('guarda y lee bool', () async {
      await storage.setKeyValue<bool>('k', true);
      expect(await storage.getValue<bool>('k'), isTrue);
    });

    test('guarda y lee double', () async {
      await storage.setKeyValue<double>('k', 3.14);
      expect(await storage.getValue<double>('k'), 3.14);
    });

    test('clave inexistente retorna null', () async {
      expect(await storage.getValue<String>('no-existe'), isNull);
    });

    test('removeKey elimina la clave', () async {
      await storage.setKeyValue<String>('k', 'valor');
      await storage.removeKey('k');
      expect(await storage.getValue<String>('k'), isNull);
    });
  });
}
