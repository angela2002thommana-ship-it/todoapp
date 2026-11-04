import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../providers/todo_provider.dart';
import 'common_widgets.dart';

class TaskCard extends StatelessWidget {
  final Todo todo;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetails;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleImportant;

  const TaskCard({
    super.key,
    required this.todo,
    required this.color,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onDetails,
    required this.onTogglePin,
    required this.onToggleImportant,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = todo.done;

    final borderColor = todo.pinned
        ? const Color.fromARGB(255, 116, 48, 233)
        : todo.important
        ? const Color.fromARGB(255, 241, 227, 29)
        : todo.done
        ? const Color.fromARGB(255, 85, 235, 72)
        : color.withValues(alpha: 0.8);

    final borderWidth = (todo.pinned || todo.important || todo.done)
        ? 3.0
        : 1.0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: color.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: onDetails,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.55),
                color.withValues(alpha: 0.28),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _topRow(),
                  const SizedBox(height: 4),
                  Text(
                    todo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? const Color.fromARGB(255, 78, 67, 233)
                          : const Color(0xFF3B3355),
                    ),
                  ),
                  if (todo.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      todo.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: Color.fromARGB(255, 60, 104, 250),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: [_priorityTag(), _categoryTag()],
                  ),
                  const SizedBox(height: 6),
                  _dateRow(),
                  if (!todo.done) ...[
                    const SizedBox(height: 8),
                    _timerControls(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timerControls(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (tick) => tick),
      builder: (context, snapshot) {
        final provider = context.watch<TodoProvider>();
        final isRunning = todo.isTimerRunning;
        final elapsedSeconds = todo.elapsedWorkSeconds;
        final hasTrackedTime = todo.trackedSeconds > 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRunning
                  ? const Color(0xFF6B8FE8)
                  : const Color(0x333B3355),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isRunning
                        ? const Color(0xFF426DD1)
                        : const Color(0xFF3B3355),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'Focus time',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B3355),
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: Color(0xFF3B3355),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _timerButton(
                      label: isRunning
                          ? 'Pause'
                          : hasTrackedTime
                          ? 'Resume'
                          : 'Start',
                      icon: isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      filled: true,
                      onPressed: () {
                        if (isRunning) {
                          provider.pauseTimer(todo);
                        } else if (hasTrackedTime) {
                          provider.resumeTimer(todo);
                        } else {
                          provider.startTimer(todo);
                        }
                      },
                    ),
                  ),
                  if (isRunning) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: _timerButton(
                        label: 'Complete',
                        icon: Icons.check_rounded,
                        filled: false,
                        onPressed: () {
                          provider.completeTodo(todo);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timerButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 30,
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: Text(label, style: const TextStyle(fontSize: 10)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                backgroundColor: const Color(0xFF6B8FE8),
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: Text(label, style: const TextStyle(fontSize: 10)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                foregroundColor: const Color(0xFF3B3355),
                side: const BorderSide(color: Color(0xFF9FAFE2)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Widget _topRow() {
    return Row(
      children: [
        IconButton(
          onPressed: onToggle,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: Icon(
            todo.done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 21,
            color: todo.done
                ? const Color.fromARGB(255, 6, 129, 10)
                : const Color(0xFF3B3355),
          ),
          tooltip: todo.done ? 'Mark pending' : 'Mark complete',
        ),
        const Spacer(),
        if (todo.important)
          const Padding(
            padding: EdgeInsets.only(right: 3),
            child: Icon(Icons.star, size: 20, color: Colors.amber),
          ),
        if (todo.pinned)
          const Padding(
            padding: EdgeInsets.only(right: 3),
            child: Icon(Icons.push_pin, size: 15, color: Colors.deepPurple),
          ),
        SizedBox(
          width: 28,
          height: 28,
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            tooltip: 'Task actions',
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: Color(0xFF3B3355),
            ),
            onSelected: (action) {
              switch (action) {
                case 'details':
                  onDetails();
                  break;
                case 'toggle':
                  onToggle();
                  break;
                case 'edit':
                  onEdit();
                  break;
                case 'pin':
                  onTogglePin();
                  break;
                case 'important':
                  onToggleImportant();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              _menuItem('details', Icons.visibility_outlined, 'View details'),
              _menuItem(
                'toggle',
                todo.done
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle_outline,
                todo.done ? 'Mark pending' : 'Mark complete',
              ),
              _menuItem('edit', Icons.edit_outlined, 'Edit task'),
              _menuItem(
                'pin',
                todo.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                todo.pinned ? 'Unpin task' : 'Pin task',
              ),
              _menuItem(
                'important',
                todo.important ? Icons.star : Icons.star_border,
                todo.important ? 'Remove importance' : 'Mark important',
              ),
              _menuItem(
                'delete',
                Icons.delete_outline,
                'Delete task',
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String title, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _priorityTag() {
    final priorityColor = switch (todo.priority) {
      Priority.none => Colors.grey,
      Priority.low => const Color.fromARGB(255, 1, 121, 5),
      Priority.medium => const Color.fromARGB(255, 124, 75, 1),
      Priority.high => const Color.fromARGB(255, 161, 13, 3),
    };

    return tag(todo.priority.name.toUpperCase(), priorityColor);
  }

  Widget _categoryTag() {
    final categoryColor = switch (todo.category) {
      Category.work => const Color.fromARGB(255, 1, 95, 172),
      Category.study => const Color.fromARGB(255, 67, 3, 179),
      Category.personal => const Color.fromARGB(255, 165, 2, 57),
      Category.health => const Color.fromARGB(255, 1, 119, 5),
      Category.finance => const Color.fromARGB(255, 167, 101, 4),
      Category.other => Colors.grey,
    };

    return tag(todo.category.name.toUpperCase(), categoryColor);
  }

  Widget _dateRow() {
    final dueDate = todo.completionDate;

    if (dueDate == null) {
      return Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 12,
            color: Colors.black,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              todo.done ? 'Completed' : 'No due date',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final daysLeft = dueDay.difference(today).inDays;

    final dateColor = todo.done
        ? const Color.fromARGB(255, 3, 94, 6)
        : daysLeft < 0
        ? const Color.fromARGB(255, 167, 14, 3)
        : daysLeft == 0
        ? const Color.fromARGB(255, 243, 60, 4)
        : const Color.fromARGB(255, 65, 44, 105);

    final dateText = todo.done
        ? 'Completed'
        : daysLeft < 0
        ? '${daysLeft.abs()}d overdue'
        : daysLeft == 0
        ? 'Due today'
        : '$daysLeft days left';

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: dateColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${dueDate.day}/${dueDate.month}/${dueDate.year}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: dateColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            dateText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 9,
              color: dateColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
