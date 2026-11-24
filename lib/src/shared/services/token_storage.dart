import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/utils/storage_keys.dart';

/// Almacena el token de sesión en el keychain (iOS) / keystore (Android)
/// en lugar de SharedPreferences (texto plano).
///
/// Migra automáticamente el token de sesiones previas guardado en
/// SharedPreferences, para no desloguear a los usuarios al actualizar la app.
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage();

  /// Caché en memoria: evita un platform channel por cada request HTTP.
  static String? _cached;
  static bool _loaded = false;

  static Future<String?> getToken() async {
    if (_loaded) return _cached;

    var token = await _storage.read(key: StorageKeys.accessToken);
    if (token == null) {
      // Migración desde SharedPreferences (versiones anteriores de la app)
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(StorageKeys.accessToken);
      if (legacy != null) {
        await _storage.write(key: StorageKeys.accessToken, value: legacy);
        await prefs.remove(StorageKeys.accessToken);
        token = legacy;
      }
    }

    _cached = token;
    _loaded = true;
    return token;
  }

  static Future<void> setToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
    _cached = token;
    _loaded = true;
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
    // Limpia también el valor legado por si la migración no llegó a correr
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.accessToken);
    _cached = null;
    _loaded = true;
  }
}
