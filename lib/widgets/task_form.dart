import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../utils/constants.dart';
import '../utils/todo_utils.dart';
import 'common_widgets.dart';
import 'video_background.dart';

class TaskForm extends StatefulWidget {
  final Todo? todo;
  final List<Color> taskColors;
  final Future<DateTime?> Function(DateTime?) pickDate;
  final String Function(DateTime) dateText;
  final int Function(DateTime) daysLeft;
  final VoidCallback onDelete;
  final void Function(Todo data, bool editing) onSave;

  const TaskForm({
    super.key,
    this.todo,
    required this.taskColors,
    required this.pickDate,
    required this.dateText,
    required this.daysLeft,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  late final TextEditingController title;
  late final TextEditingController description;
  final sub = TextEditingController();

  late Priority priority;
  late Category category;
  late Repeat repeat;
  late bool important;
  late bool pinned;
  late bool done;
  late DateTime? due;
  late int colorIndex;
  late int estimatedMinutes;
  late List<SubTask> subtasks;

  bool get editing => widget.todo != null;

  @override
  void initState() {
    super.initState();

    final todo = widget.todo;

    title = TextEditingController(text: todo?.title ?? '');

    description = TextEditingController(text: todo?.description ?? '');

    priority = todo?.priority ?? Priority.none;
    category = todo?.category ?? Category.other;
    repeat = todo?.repeat ?? Repeat.none;
    important = todo?.important ?? false;
    pinned = todo?.pinned ?? false;
    done = todo?.done ?? false;
    due = todo?.completionDate;
    colorIndex = todo?.colorIndex ?? 0;
    estimatedMinutes = todo?.estimatedMinutes ?? 30;

    subtasks = todo == null
        ? []
        : todo.subtasks.map((s) => SubTask(s.title, done: s.done)).toList();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    sub.dispose();
    super.dispose();
  }

  void save() {
    if (title.text.trim().isEmpty) return;

    final old = widget.todo;

    final data = Todo(
      id: old?.id ?? DateTime.now().toString(),
      title: title.text.trim(),
      description: description.text.trim(),
      priority: priority,
      category: category,
      repeat: repeat,
      important: important,
      pinned: pinned,
      done: done,
      completionDate: due,
      subtasks: subtasks,
      colorIndex: colorIndex,
      estimatedMinutes: estimatedMinutes,
      actualCompletionDate: done
          ? old?.actualCompletionDate ?? DateTime.now()
          : null,
      createdAt: old?.createdAt,
    );

    widget.onSave(data, editing);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .93,
        child: VideoBackground(
          overlayColor: Colors.transparent,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              MediaQuery.of(context).viewInsets.bottom + 15,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        editing ? 'Edit Task' : 'Add Task',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 240, 239, 243),
                        ),
                      ),
                    ),
                    if (editing)
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDelete();
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: title,
                  decoration: inputDecoration('Task title', Icons.task_alt),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: inputDecoration('Description', Icons.description),
                ),
                const SizedBox(height: 14),
                sectionTitle('Priority'),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: 1.5,
                  children: Priority.values.map((p) {
                    return ChoiceChip(
                      label: Text(
                        priorityName(p),
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: priority == p,
                      onSelected: (_) {
                        setState(() => priority = p);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                sectionTitle('Category'),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 2,
                  children: Category.values.map((c) {
                    return ChoiceChip(
                      label: Text(categoryName(c)),
                      selected: category == c,
                      onSelected: (_) {
                        setState(() => category = c);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                sectionTitle('Task Options'),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 2,
                  children: [
                    optionCard(
                      'Important',
                      Icons.star,
                      important,
                      () => setState(() => important = !important),
                    ),
                    optionCard(
                      'Pinned',
                      Icons.push_pin,
                      pinned,
                      () => setState(() => pinned = !pinned),
                    ),
                    optionCard(
                      'Completed',
                      Icons.check_circle,
                      done,
                      () => setState(() => done = !done),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                sectionTitle('Completion Date'),
                InkWell(
                  onTap: () async {
                    final date = await widget.pickDate(due);

                    if (date != null) {
                      setState(() => due = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            due == null ? 'Select date' : widget.dateText(due!),
                          ),
                        ),
                        if (due != null)
                          IconButton(
                            onPressed: () {
                              setState(() => due = null);
                            },
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                  ),
                ),
                if (due != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      daysText(due!),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: widget.daysLeft(due!) < 0
                            ? Colors.red
                            : const Color.fromARGB(255, 239, 245, 240),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                sectionTitle('Repeat'),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 3,
                  childAspectRatio: 1.5,
                  children: Repeat.values.map((r) {
                    return ChoiceChip(
                      label: Text(
                        repeatName(r),
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: repeat == r,
                      onSelected: (_) {
                        setState(() => repeat = r);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                sectionTitle('Estimated Time'),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 3,
                  childAspectRatio: 1.5,
                  children: [15, 30, 60, 120].map((m) {
                    final selected = estimatedMinutes == m;

                    return InkWell(
                      onTap: () {
                        setState(() => estimatedMinutes = m);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.lightPrimary.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color.fromARGB(255, 137, 202, 245)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(m < 60 ? '$m min' : '${m ~/ 60} hr'),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                sectionTitle('Task Color'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.taskColors.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 2,
                  ),
                  itemBuilder: (_, i) {
                    return InkWell(
                      onTap: () {
                        setState(() => colorIndex = i);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.taskColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorIndex == i
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: colorIndex == i
                            ? const Icon(Icons.check, size: 17)
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                sectionTitle('Subtasks'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sub,
                        decoration: inputDecoration(
                          'Add Subtask',
                          Icons.subdirectory_arrow_right,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (sub.text.trim().isEmpty) return;

                        setState(() {
                          subtasks.add(SubTask(sub.text.trim()));
                          sub.clear();
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subtasks.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                    childAspectRatio: 2,
                  ),
                  itemBuilder: (_, i) {
                    final s = subtasks[i];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: s.done,
                            onChanged: (v) {
                              setState(() => s.done = v ?? false);
                            },
                          ),
                          Expanded(
                            child: Text(
                              s.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => subtasks.removeAt(i));
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 4, 38, 150),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(editing ? 'Save Changes' : 'Add Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
