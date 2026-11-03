import 'package:flutter/material.dart';

import '../models/todo.dart';

int daysLeft(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final target = DateTime(
    date.year,
    date.month,
    date.day,
  );

  return target.difference(today).inDays;
}

int priorityValue(Priority p) {
  return switch (p) {
    Priority.high => 3,
    Priority.medium => 2,
    Priority.low => 1,
    Priority.none => 0,
  };
}

int subDone(Todo todo) {
  return todo.subtasks
      .where((s) => s.done)
      .length;
}

double taskProgress(Todo todo) {
  if (todo.subtasks.isEmpty) {
    return todo.done ? 1 : 0;
  }

  return subDone(todo) /
      todo.subtasks.length;
}

String progressText(Todo todo) {
  if (todo.subtasks.isEmpty) {
    return todo.done ? '100%' : '0%';
  }

  return '${(taskProgress(todo) * 100).round()}%';
}

String dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String daysText(DateTime date) {
  final d = daysLeft(date);

  if (d < 0) {
    return '${d.abs()}d overdue';
  }

  if (d == 0) {
    return 'Due today';
  }

  return '$d days left';
}

String dueStatus(DateTime date) {
  final d = daysLeft(date);

  if (d < 0) return 'OVERDUE';

  if (d == 0) return 'TODAY';

  if (d == 1) return 'TOMORROW';

  return '$d DAYS';
}

String priorityName(Priority p) {
  return p.name[0].toUpperCase() +
      p.name.substring(1);
}

String categoryName(Category c) {
  return c.name[0].toUpperCase() +
      c.name.substring(1);
}

String repeatName(Repeat r) {
  return r.name[0].toUpperCase() +
      r.name.substring(1);
}

String filterName(Filter f) {
  return switch (f) {
    Filter.all => 'All',
    Filter.important => 'Important',
    Filter.pinned => 'Pinned',
    Filter.pending => 'Pending',
    Filter.completed => 'Completed',
    Filter.overdue => 'Overdue',
    Filter.today => 'Today',
    Filter.high => 'High',
    Filter.medium => 'Medium',
    Filter.low => 'Low',
  };
}

IconData filterIcon(Filter f) {
  return switch (f) {
    Filter.all => Icons.apps,
    Filter.important => Icons.star,
    Filter.pinned => Icons.push_pin,
    Filter.pending => Icons.pending_actions,
    Filter.completed => Icons.check_circle,
    Filter.overdue => Icons.warning,
    Filter.today => Icons.today,
    Filter.high => Icons.priority_high,
    Filter.medium => Icons.flag,
    Filter.low => Icons.low_priority,
  };
}

String sortName(SortType s) {
  return switch (s) {
    SortType.smart => 'Smart',
    SortType.dueDate => 'Due Date',
    SortType.priority => 'Priority',
    SortType.alphabetical => 'A-Z',
    SortType.newest => 'Newest',
  };
}

Color priorityColor(Priority p) {
  return switch (p) {
    Priority.high => Colors.red,
    Priority.medium => Colors.orange,
    Priority.low => Colors.green,
    Priority.none => Colors.grey,
  };
}

String formatMinutes(int minutes) {
  if (minutes < 60) {
    return '$minutes min';
  }

  final h = minutes ~/ 60;
  final m = minutes % 60;

  return m == 0
      ? '$h hr'
      : '$h hr $m min';
}