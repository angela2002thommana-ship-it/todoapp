import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';

class SharedPreferencesService {
  static const String _storageKey = 'saved_todos';
  static const String _migrationKey = 'saved_todos_migrated_to_firebase';

  String _userStorageKey(String uid) => 'saved_todos_user_$uid';

  Future<List<Todo>> _readTodos(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(key);

    if (savedData == null) return [];

    try {
      final decodedData = jsonDecode(savedData) as List;

      return decodedData.map((item) {
        return Todo.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();
    } catch (error) {
      return [];
    }
  }

  Future<void> _writeTodos(String key, List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();

    final data = todos.map((todo) => todo.toJson()).toList();

    await prefs.setString(key, jsonEncode(data));
  }

  Future<List<Todo>> loadTodos() => _readTodos(_storageKey);

  Future<void> saveTodos(List<Todo> todos) => _writeTodos(_storageKey, todos);

  Future<void> clearTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<List<Todo>> loadTodosForUser(String uid) {
    return _readTodos(_userStorageKey(uid));
  }

  Future<void> saveTodosForUser(String uid, List<Todo> todos) {
    return _writeTodos(_userStorageKey(uid), todos);
  }

  Future<List<Todo>> loadLegacyTodos() => loadTodos();

  Future<bool> hasMigratedLegacyTodos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  Future<void> markLegacyTodosMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }
}
