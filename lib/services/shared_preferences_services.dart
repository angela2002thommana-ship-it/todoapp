import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  Future<bool> saveBool(String key, bool value) async {
    final prefs = await _prefs;
    return prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _prefs;
    return prefs.getBool(key);
  }

  Future<bool> saveString(String key, String value) async {
    final prefs = await _prefs;
    return prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<bool> saveInt(String key, int value) async {
    final prefs = await _prefs;
    return prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt(key);
  }

  Future<bool> saveDouble(String key, double value) async {
    final prefs = await _prefs;
    return prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _prefs;
    return prefs.getDouble(key);
  }

  Future<bool> removeSetting(String key) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }

  Future<bool> clearSettings() async {
    final prefs = await _prefs;
    return prefs.clear();
  }
}
