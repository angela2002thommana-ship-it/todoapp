
enum Priority { none, low, medium, high }

enum Category {
  work,
  study,
  personal,
  health,
  finance,
  other,
}

enum Repeat { none, daily, weekly, monthly }

enum Filter {
  all,
  important,
  pinned,
  pending,
  completed,
  overdue,
  today,
  high,
  medium,
  low,
}

enum SortType {
  smart,
  dueDate,
  priority,
  alphabetical,
  newest,
}

class SubTask {
  String title;
  bool done;

  SubTask(
    this.title, {
    this.done = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'done': done,
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      json['title'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }
}

class Todo {
  String id;
  String title;
  String description;
  bool done;
  bool important;
  bool pinned;
  Priority priority;
  Category category;
  Repeat repeat;
  List<SubTask> subtasks;
  DateTime? completionDate;
  DateTime? actualCompletionDate;
  DateTime createdAt;
  int estimatedMinutes;
  int colorIndex;

  int trackedSeconds;
  DateTime? timerStartedAt;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.done = false,
    this.important = false,
    this.pinned = false,
    this.priority = Priority.none,
    this.category = Category.other,
    this.repeat = Repeat.none,
    this.subtasks = const [],
    this.completionDate,
    this.actualCompletionDate,
    DateTime? createdAt,
    this.estimatedMinutes = 30,
    this.colorIndex = 0,
    this.trackedSeconds = 0,
    this.timerStartedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isTimerRunning => timerStartedAt != null;

  int get elapsedWorkSeconds {
    final activeStart = timerStartedAt;

    if (activeStart == null) {
      return trackedSeconds;
    }

    final currentSessionSeconds =
        DateTime.now().difference(activeStart).inSeconds;

    return trackedSeconds +
        (currentSessionSeconds > 0 ? currentSessionSeconds : 0);
  }

  int get actualDurationMinutes =>
      (elapsedWorkSeconds / 60).round();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'done': done,
      'important': important,
      'pinned': pinned,
      'priority': priority.name,
      'category': category.name,
      'repeat': repeat.name,
      'subtasks': subtasks
          .map((subtask) => subtask.toJson())
          .toList(),
      'completionDate': completionDate?.toIso8601String(),
      'actualCompletionDate':
          actualCompletionDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'colorIndex': colorIndex,

      'trackedSeconds': trackedSeconds,
      'timerStartedAt': timerStartedAt?.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      important: json['important'] as bool? ?? false,
      pinned: json['pinned'] as bool? ?? false,
      priority: Priority.values.firstWhere(
        (value) => value.name == json['priority'],
        orElse: () => Priority.none,
      ),
      category: Category.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => Category.other,
      ),
      repeat: Repeat.values.firstWhere(
        (value) => value.name == json['repeat'],
        orElse: () => Repeat.none,
      ),
      subtasks: (json['subtasks'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (item) => SubTask.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      completionDate: _parseDate(json['completionDate']),
      actualCompletionDate:
          _parseDate(json['actualCompletionDate']),
      createdAt:
          _parseDate(json['createdAt']) ?? DateTime.now(),
      estimatedMinutes:
          json['estimatedMinutes'] as int? ?? 30,
      colorIndex: json['colorIndex'] as int? ?? 0,

      trackedSeconds: (json['trackedSeconds'] as num?)?.toInt() ?? 0,
      timerStartedAt: _parseDate(json['timerStartedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;

    return DateTime.tryParse(value);
  }
}
