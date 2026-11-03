import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/todo.dart';
import '../services/firestore_todo_service.dart';
import '../services/shared_preferences_services.dart';
import '../utils/todo_utils.dart';

class TodoProvider extends ChangeNotifier {
  TodoProvider({required this.userId});

  final String userId;
  final SharedPreferencesService _storage = SharedPreferencesService();
  final FirestoreTodoService _cloud = FirestoreTodoService.instance;

  final List<Todo> _todos = [];

  bool _isLoading = true;
  bool _cloudReady = false;
  Future<void> _saveQueue = Future<void>.value();

  List<Todo> get todos => List.unmodifiable(_todos);
  bool get isLoading => _isLoading;

  int get completed => _todos.where((todo) => todo.done).length;
  int get pending => _todos.where((todo) => !todo.done).length;
  int get pinned => _todos.where((todo) => todo.pinned).length;

  int get overdue {
    return _todos.where((todo) {
      return !todo.done &&
          todo.completionDate != null &&
          daysLeft(todo.completionDate!) < 0;
    }).length;
  }

  double get progress {
    if (_todos.isEmpty) return 0;
    return completed / _todos.length;
  }

  Todo? get runningTodo {
    for (final todo in _todos) {
      if (todo.isTimerRunning && !todo.done) return todo;
    }
    return null;
  }

  int get completedToday {
    final now = DateTime.now();

    return _todos.where((todo) {
      final date = todo.actualCompletionDate;

      return todo.done &&
          date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get totalTrackedSeconds {
    return _todos.fold<int>(
      0,
      (total, todo) => total + todo.elapsedWorkSeconds,
    );
  }

  int get trackedMinutes => (totalTrackedSeconds / 60).round();

  String get dailyAchievementSummary {
    final finished = completedToday;
    final total = _todos.length;
    final time = _formatDuration(totalTrackedSeconds);

    if (total == 0) {
      return 'A fresh start! Add a task and begin your progress.';
    }

    if (finished == 0) {
      return 'You have tracked $time of focused work. '
          'Keep going — every small step counts!';
    }

    if (finished == 1) {
      return 'You completed 1 task today and tracked $time. '
          'A great step forward!';
    }

    return 'You completed $finished tasks today and tracked '
        '$time. You are making meaningful progress!';
  }

  Future<void> loadTodos() async {
    _isLoading = true;
    _cloudReady = false;
    notifyListeners();

    try {
      final localTodos = await _storage.loadTodosForUser(userId);
      final alreadyMigrated = await _storage.hasMigratedLegacyTodos();

      List<Todo> legacyTodos = [];
      if (!alreadyMigrated) {
        legacyTodos = await _storage.loadLegacyTodos();
      }

      List<Todo>? cloudTodos;

      try {
        cloudTodos = await _cloud.loadTodos(userId);
      } catch (error) {
        debugPrint('Could not load cloud tasks: $error');
      }

      final merged = <String, Todo>{};

      for (final todo in localTodos) {
        merged[todo.id] = todo;
      }

      for (final todo in legacyTodos) {
        merged.putIfAbsent(todo.id, () => todo);
      }

      if (cloudTodos != null) {
        for (final todo in cloudTodos) {
          merged[todo.id] = todo;
        }
      }

      _todos
        ..clear()
        ..addAll(merged.values);

      for (final todo in _todos) {
        if (todo.done && todo.timerStartedAt != null) {
          _pauseTaskTimer(todo);
        }
      }

      final runningTasks =
          _todos
              .where((todo) => !todo.done && todo.timerStartedAt != null)
              .toList()
            ..sort((a, b) => b.timerStartedAt!.compareTo(a.timerStartedAt!));

      for (var i = 1; i < runningTasks.length; i++) {
        _pauseTaskTimer(runningTasks[i]);
      }

      await _storage.saveTodosForUser(userId, _snapshot());

      if (cloudTodos != null) {
        try {
          await _cloud.saveTodos(userId, _snapshot());
          _cloudReady = true;

          if (!alreadyMigrated) {
            await _storage.markLegacyTodosMigrated();
          }
        } catch (error) {
          debugPrint('Could not synchronize tasks: $error');
        }
      }
    } catch (error) {
      debugPrint('Error loading tasks: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Todo> _snapshot() {
    return _todos.map((todo) => Todo.fromJson(todo.toJson())).toList();
  }

  Future<void> _saveTodos() {
    final snapshot = _snapshot();

    _saveQueue = _saveQueue.then((_) async {
      try {
        await _storage.saveTodosForUser(userId, snapshot);
      } catch (error) {
        debugPrint('Error saving local tasks: $error');
      }

      if (_cloudReady) {
        try {
          await _cloud.saveTodos(userId, snapshot);
        } catch (error) {
          debugPrint('Error synchronizing cloud tasks: $error');
        }
      }
    });

    return _saveQueue;
  }

  void refresh() {
    notifyListeners();
    unawaited(_saveTodos());
  }

  void addTodo(Todo todo) {
    _todos.add(todo);
    notifyListeners();
    unawaited(_saveTodos());
  }

  void updateTodo(Todo updatedTodo) {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index == -1) return;

    _todos[index] = updatedTodo;
    notifyListeners();
    unawaited(_saveTodos());
  }

  void startTimer(Todo todo) {
    final task = _findTodo(todo.id);
    if (task == null || task.done || task.timerStartedAt != null) return;

    for (final other in _todos) {
      if (other.id != task.id && other.timerStartedAt != null) {
        _pauseTaskTimer(other);
      }
    }

    task.timerStartedAt = DateTime.now();
    notifyListeners();
    unawaited(_saveTodos());
  }

  void pauseTimer(Todo todo) {
    final task = _findTodo(todo.id);
    if (task == null || task.timerStartedAt == null) return;

    _pauseTaskTimer(task);
    notifyListeners();
    unawaited(_saveTodos());
  }

  void resumeTimer(Todo todo) => startTimer(todo);

  void resetTimer(Todo todo) {
    final task = _findTodo(todo.id);
    if (task == null) return;

    task.trackedSeconds = 0;
    task.timerStartedAt = null;

    notifyListeners();
    unawaited(_saveTodos());
  }

  void _pauseTaskTimer(Todo task) {
    final startedAt = task.timerStartedAt;
    if (startedAt == null) return;

    final elapsed = DateTime.now().difference(startedAt).inSeconds;

    if (elapsed > 0) {
      task.trackedSeconds += elapsed;
    }

    task.timerStartedAt = null;
  }

  void completeTodo(Todo todo) {
    final task = _findTodo(todo.id);
    if (task == null || task.done) return;

    _pauseTaskTimer(task);
    task.done = true;
    task.actualCompletionDate = DateTime.now();

    notifyListeners();
    unawaited(_saveTodos());
  }

  void toggleTodo(Todo todo) {
    final task = _findTodo(todo.id);
    if (task == null) return;

    if (!task.done) {
      _pauseTaskTimer(task);
      task.done = true;
      task.actualCompletionDate = DateTime.now();
    } else {
      task.done = false;
      task.actualCompletionDate = null;
    }

    notifyListeners();
    unawaited(_saveTodos());
  }

  void togglePin(Todo todo) {
    final task = _findTodo(todo.id);
    if (task == null) return;

    task.pinned = !task.pinned;
    notifyListeners();
    unawaited(_saveTodos());
  }

  void toggleImportant(Todo todo) {
    final task = _findTodo(todo.id);
    if (task == null) return;

    task.important = !task.important;
    notifyListeners();
    unawaited(_saveTodos());
  }

  int deleteTodo(Todo todo) {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return -1;

    _todos.removeAt(index);
    notifyListeners();
    unawaited(_saveTodos());

    return index;
  }

  void restoreTodo(Todo todo, int index) {
    if (_todos.any((item) => item.id == todo.id)) return;

    final safeIndex = index.clamp(0, _todos.length).toInt();
    _todos.insert(safeIndex, todo);

    notifyListeners();
    unawaited(_saveTodos());
  }

  Todo? _findTodo(String id) {
    for (final todo in _todos) {
      if (todo.id == id) return todo;
    }
    return null;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
