import 'package:shared_preferences/shared_preferences.dart';
import 'key_value_storage.dart';



class KeyValueStorageServiceImpl extends KeyValueStorageService {

  Future<SharedPreferences> getSharedPrefs() async {
    return await SharedPreferences.getInstance();
  }


  @override
  Future<T?> getValue<T>(String key) async{
    final prefs = await getSharedPrefs();

    switch(T) {
      case const (int):
        return prefs.getInt( key ) as T?;

      case const (String):
        return prefs.getString(key) as T?;

      case const (bool):
        return prefs.getBool(key) as T?;

      case const (double):
        return prefs.getDouble(key) as T?;

      default:
        // Compatibilidad: llamadas sin tipo (T = dynamic) leen como String.
        return prefs.getString(key) as T?;
    }
  }

  @override
  Future<bool> removeKey(String key) async {
    final prefs = await getSharedPrefs();
    return await prefs.remove(key);
  }

  @override
  Future<void> setKeyValue<T>(String key, T value) async {
    final prefs = await getSharedPrefs();

    switch(T) {
      case const (int):
        prefs.setInt( key, value as int );
        break;

      case const (String):
        prefs.setString(key, value as String);
        break;

      case const (bool):
        prefs.setBool(key, value as bool);
        break;

      case const (double):
        prefs.setDouble(key, value as double);
        break;

      default:
        // Compatibilidad: llamadas sin tipo (T = dynamic) escriben como String.
        prefs.setString(key, value as String);
    }

  }

}