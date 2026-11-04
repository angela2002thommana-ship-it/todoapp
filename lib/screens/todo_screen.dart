import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../utils/todo_utils.dart';
import '../widgets/common_widgets.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form.dart';
import '../widgets/video_background.dart';
import '../widgets/animated_card.dart';
import 'calender_page.dart';
import 'insights_page.dart';

class TodoScreen extends StatefulWidget {
  final bool enableVideo;

  const TodoScreen({super.key, this.enableVideo = true});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> get todos => context.read<TodoProvider>().todos;

  final TextEditingController search = TextEditingController();

  String query = '';
  Filter filter = Filter.all;
  SortType sortType = SortType.smart;
  Category? categoryFilter;

  List<Color> get taskColors => const [
    Color.fromARGB(255, 248, 247, 247),
    Color.fromARGB(255, 204, 242, 245),
  ];

  @override
  void initState() {
    super.initState();

    search.addListener(() {
      setState(() {
        query = search.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<Todo> get filtered {
    final list = todos.where((todo) {
      final title = todo.title.toLowerCase();
      final description = todo.description.toLowerCase();

      final matches = title.contains(query) || description.contains(query);

      if (!matches) return false;

      if (categoryFilter != null && todo.category != categoryFilter) {
        return false;
      }

      return switch (filter) {
        Filter.all => true,
        Filter.important => todo.important,
        Filter.pinned => todo.pinned,
        Filter.pending => !todo.done,
        Filter.completed => todo.done,
        Filter.overdue =>
          !todo.done &&
              todo.completionDate != null &&
              daysLeft(todo.completionDate!) < 0,
        Filter.today =>
          !todo.done &&
              todo.completionDate != null &&
              daysLeft(todo.completionDate!) == 0,
        Filter.high => todo.priority == Priority.high,
        Filter.medium => todo.priority == Priority.medium,
        Filter.low => todo.priority == Priority.low,
      };
    }).toList();

    list.sort((a, b) {
      if (sortType == SortType.smart) {
        if (a.done != b.done) {
          return a.done ? 1 : -1;
        }

        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }

        if (a.important != b.important) {
          return a.important ? -1 : 1;
        }

        if (a.completionDate != null && b.completionDate != null) {
          final result = daysLeft(a.completionDate!)
              .compareTo(daysLeft(b.completionDate!));

          if (result != 0) return result;
        }

        if (a.completionDate != null) return -1;
        if (b.completionDate != null) return 1;

        return priorityValue(b.priority).compareTo(priorityValue(a.priority));
      }

      if (sortType == SortType.dueDate) {
        if (a.completionDate == null) return 1;
        if (b.completionDate == null) return -1;

        return daysLeft(a.completionDate!)
            .compareTo(daysLeft(b.completionDate!));
      }

      if (sortType == SortType.priority) {
        return priorityValue(b.priority).compareTo(priorityValue(a.priority));
      }

      if (sortType == SortType.alphabetical) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    return list;
  }

  int get completed => context.read<TodoProvider>().completed;

  int get pending => context.read<TodoProvider>().pending;

  int get overdue => context.read<TodoProvider>().overdue;

  int get pinned => context.read<TodoProvider>().pinned;

  double get progress => context.read<TodoProvider>().progress;

  Future<DateTime?> pickDate(DateTime? date) {
    return showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2026),
      lastDate: DateTime(2100),
    );
  }

  void toggle(Todo todo) {
    context.read<TodoProvider>().toggleTodo(todo);
  }

  void togglePin(Todo todo) {
    context.read<TodoProvider>().togglePin(todo);
  }

  void toggleImportant(Todo todo) {
    context.read<TodoProvider>().toggleImportant(todo);
  }

  void deleteTodo(Todo todo) {
    final provider = context.read<TodoProvider>();
    final index = provider.deleteTodo(todo);

    if (index == -1) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            provider.restoreTodo(todo, index);
          },
        ),
      ),
    );
  }

  void openTask([Todo? todo]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return TaskForm(
          todo: todo,
          taskColors: taskColors,
          pickDate: pickDate,
          dateText: dateText,
          daysLeft: daysLeft,
          onDelete: () {
            if (todo != null) {
              deleteTodo(todo);
            }
          },
          onSave: (data, editing) {
            final provider = context.read<TodoProvider>();

            if (editing) {
              provider.updateTodo(data);
            } else {
              provider.addTodo(data);
            }
          },
        );
      },
    );
  }

  void openCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return CalendarPage(
            todos: todos,
            taskColors: taskColors,
            onChanged: () {
              context.read<TodoProvider>().refresh();
            },
          );
        },
      ),
    );
  }

  void openInsights() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsightsPage(todos: todos)),
    );
  }

  int taskColumns(double width) {
    if (width < 500) return 2;
    if (width < 800) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  double contentGap(double width) {
    if (width < 500) return 8;
    if (width < 900) return 10;
    return 12;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final width = MediaQuery.of(context).size.width;
    final columns = taskColumns(width);
    final gap = contentGap(width);

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return VideoBackground(
      overlayColor: Colors.transparent,
      enableVideo: widget.enableVideo,

      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(width < 500 ? 10 : 16),
            child: Column(
              children: [
                _header(width),
                const SizedBox(height: 12),
                _stats(width),
                const SizedBox(height: 12),
                _searchRow(width),
                const SizedBox(height: 10),
                _progress(width),
                const SizedBox(height: 12),
                _tasks(width, columns, gap),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => openTask(),
          backgroundColor: const Color.fromARGB(255, 35, 99, 151),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _header(double width) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width < 500 ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(234, 1, 43, 99),
            Color.fromARGB(120, 23, 93, 184),
            Color.fromARGB(155, 215, 228, 245),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'My Todo List',
              style: TextStyle(
                color: const Color.fromARGB(255, 248, 247, 252),
                fontSize: width < 500 ? 22 : 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: showFilters,
            tooltip: 'Filter',
            icon: const Icon(Icons.tune),
            color: const Color.fromARGB(255, 2, 41, 73),
          ),
          IconButton(
            onPressed: openCalendar,
            tooltip: 'Calendar',
            icon: const Icon(Icons.calendar_month),
            color: const Color.fromARGB(255, 2, 41, 73),
          ),
          IconButton(
            onPressed: openInsights,
            tooltip: 'Insights',
            icon: const Icon(Icons.insights),
            color: const Color.fromARGB(255, 2, 41, 73),
          ),
        ],
      ),
    );
  }

  Widget _stats(double width) {
    return GridView.count(
      crossAxisCount: 5,
      crossAxisSpacing: width < 500 ? 5 : 8,
      mainAxisSpacing: width < 500 ? 5 : 8,
      childAspectRatio: width < 500 ? 1.05 : 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        AnimatedCard(
          delay: 0,
          duration: const Duration(milliseconds: 800),
          beginScale: 0.65,
          slideOffset: 60,
          child: statCard(
            'Total',
            '${todos.length}',
            Icons.list_alt,
            backgroundColor: const Color.fromARGB(101, 225, 240, 255),
            textColor: const Color(0xFF15508A),
            iconColor: const Color(0xFF2980D9),
          ),
        ),
        AnimatedCard(
          delay: 0,
          duration: const Duration(milliseconds: 800),
          beginScale: 0.65,
          slideOffset: 60,
          child: statCard(
            'Done',
            '$completed',
            Icons.check_circle,
            backgroundColor: const Color.fromARGB(125, 225, 240, 255),
            textColor: const Color(0xFF15508A),
            iconColor: const Color(0xFF2980D9),
          ),
        ),
        AnimatedCard(
          delay: 0,
          duration: const Duration(milliseconds: 800),
          beginScale: 0.65,
          slideOffset: 60,
          child: statCard(
            'Pending',
            '$pending',
            Icons.pending_actions,
            backgroundColor: const Color.fromARGB(120, 225, 240, 255),
            textColor: const Color(0xFF15508A),
            iconColor: const Color(0xFF2980D9),
          ),
        ),
        AnimatedCard(
          delay: 0,
          duration: const Duration(milliseconds: 800),
          beginScale: 0.65,
          slideOffset: 60,
          child: statCard(
            'Overdue',
            '$overdue',
            Icons.warning,
            backgroundColor: const Color.fromARGB(24, 225, 240, 255),
            textColor: const Color(0xFF15508A),
            iconColor: const Color(0xFF2980D9),
          ),
        ),
        AnimatedCard(
          delay: 0,
          duration: const Duration(milliseconds: 800),
          beginScale: 0.65,
          slideOffset: 60,
          child: statCard(
            'Pinned',
            '$pinned',
            Icons.push_pin,
            backgroundColor: const Color.fromARGB(26, 225, 240, 255),
            textColor: const Color(0xFF15508A),
            iconColor: const Color(0xFF2980D9),
          ),
        ),
      ],
    );
  }

  Widget _searchRow(double width) {
    const pastelGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.fromARGB(255, 27, 29, 31),
        Color.fromARGB(255, 43, 31, 214),
        Color.fromARGB(255, 13, 142, 165),
      ],
    );

    return TextField(
      controller: search,
      style: const TextStyle(color: Color.fromARGB(255, 23, 44, 228)),
      decoration: inputDecoration('', Icons.search).copyWith(
        prefixIcon: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return pastelGradient.createShader(bounds);
          },
          child: const Icon(
            Icons.search,
            color: Color.fromARGB(255, 20, 125, 167),
            size: 32,
          ),
        ),
        hint: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return pastelGradient.createShader(bounds);
          },
          child: const Text(
            'Search Tasks',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        suffixIcon: IconButton(
          tooltip: 'Clear Search',
          icon: const Icon(
            Icons.delete_outline,
            color: Color.fromARGB(255, 1, 40, 146),
            size: 26,
          ),
          onPressed: () async {
            if (search.text.isEmpty) return;

            final shouldClear = await showDialog<bool>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'Clear Search?',
                    style: TextStyle(
                      color: Color(0xFF493347),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'Do you want to delete the search text?',
                    style: TextStyle(color: Color.fromARGB(255, 63, 2, 78)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, false);
                      },
                      child: const Text('No'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          18,
                          118,
                          212,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Yes'),
                    ),
                  ],
                );
              },
            );

            if (shouldClear == true && mounted) {
              search.clear();
            }
          },
        ),
      ),
    );
  }

  Widget _progress(double width) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.fromARGB(255, 6, 15, 36),
                      Color.fromARGB(255, 4, 56, 168),
                      Color.fromARGB(255, 25, 83, 209),
                      Color.fromARGB(255, 1, 104, 145),
                    ],
                  ).createShader(bounds);
                },
                child: const Text(
                  'Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Color.fromARGB(255, 49, 81, 184),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 7,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFE5E5E5)),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 3, 69, 112),
                            Color.fromARGB(255, 127, 201, 235),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tasks(double width, int columns, double gap) {
    final tasks = filtered;

    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: const Column(
          children: [
            Icon(Icons.task_alt, size: 45, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No Tasks Found',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: width < 500
            ? 0.82
            : width < 800
            ? 0.90
            : width < 1200
            ? 0.95
            : 1.05,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final todo = tasks[index];

        return TaskCard(
          todo: todo,
          color: taskColors[todo.colorIndex.abs() % taskColors.length],
          onToggle: () => toggle(todo),
          onEdit: () => openTask(todo),
          onDelete: () => deleteTodo(todo),
          onDetails: () => showDetails(todo),
          onTogglePin: () => togglePin(todo),
          onToggleImportant: () => toggleImportant(todo),
        );
      },
    );
  }

  void showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) {
        final width = MediaQuery.of(sheet).size.width;
        final height = MediaQuery.of(sheet).size.height;

        final columns = width < 500
            ? 2
            : width < 900
            ? 3
            : 4;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: SizedBox(
            height: height * 0.85,
            child: VideoBackground(
              overlayColor: Colors.transparent,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      sectionTitle('Filter'),
                      GridView.count(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: Filter.values.map((value) {
                          return optionCard(
                            filterName(value),
                            filterIcon(value),
                            filter == value,
                            () {
                              setState(() {
                                filter = value;
                              });
                              Navigator.pop(sheet);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      sectionTitle('Sort'),
                      GridView.count(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: SortType.values.map((value) {
                          return optionCard(
                            sortName(value),
                            Icons.sort,
                            sortType == value,
                            () {
                              setState(() {
                                sortType = value;
                              });
                              Navigator.pop(sheet);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      sectionTitle('Category'),
                      GridView.count(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          optionCard(
                            'All',
                            Icons.apps,
                            categoryFilter == null,
                            () {
                              setState(() {
                                categoryFilter = null;
                              });
                              Navigator.pop(sheet);
                            },
                          ),
                          ...Category.values.map((value) {
                            return optionCard(
                              categoryName(value),
                              Icons.category,
                              categoryFilter == value,
                              () {
                                setState(() {
                                  categoryFilter = value;
                                });
                                Navigator.pop(sheet);
                              },
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showDetails(Todo todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) {
        final width = MediaQuery.of(sheet).size.width;

        final columns = width < 500
            ? 2
            : width < 900
            ? 3
            : 4;

        return TaskDetailsSheet(
          todo: todo,
          columns: columns,
          status: todo.done ? 'Completed' : 'Pending',
          priority: priorityName(todo.priority),
          category: categoryName(todo.category),
          repeat: repeatName(todo.repeat),
          important: todo.important ? 'Yes' : 'No',
          pinned: todo.pinned ? 'Yes' : 'No',
          description: todo.description,
          completionDate: todo.completionDate == null
              ? null
              : dateText(todo.completionDate!),
          onEdit: () {
            Navigator.pop(sheet);
            openTask(todo);
          },
        );
      },
    );
  }
}

class TaskDetailsSheet extends StatelessWidget {
  final Todo todo;
  final int columns;
  final String status;
  final String priority;
  final String category;
  final String repeat;
  final String important;
  final String pinned;
  final String description;
  final String? completionDate;
  final VoidCallback onEdit;

  const TaskDetailsSheet({
    super.key,
    required this.todo,
    required this.columns,
    required this.status,
    required this.priority,
    required this.category,
    required this.repeat,
    required this.important,
    required this.pinned,
    required this.description,
    required this.completionDate,
    required this.onEdit,
  });

  Widget infoCard(String title, String value) {
    const gradients = [
      [Color(0xFFC8E9FF), Color(0xFFEAF7FF)],
      [Color.fromARGB(255, 184, 225, 253), Color(0xFFEAF7FF)],
      [Color.fromARGB(255, 159, 214, 250), Color(0xFFEAF7FF)],
      [Color.fromARGB(255, 153, 206, 241), Color(0xFFEAF7FF)],
      [Color.fromARGB(255, 155, 196, 223), Color(0xFFEAF7FF)],
      [Color.fromARGB(255, 148, 183, 206), Color(0xFFEAF7FF)],
    ];

    final index = switch (title) {
      'Status' => 0,
      'Priority' => 1,
      'Category' => 2,
      'Repeat' => 3,
      'Important' => 4,
      'Pinned' => 5,
      'Completion Date' => 0,
      _ => 0,
    };

    final delay = switch (title) {
      'Status' => 0,
      'Priority' => 70,
      'Category' => 140,
      'Repeat' => 210,
      'Important' => 280,
      'Pinned' => 350,
      'Completion Date' => 420,
      _ => 0,
    };

    return AnimatedCard(
      delay: delay,
      duration: const Duration(milliseconds: 500),
      beginScale: 0.85,
      slideOffset: 12,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradients[index],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.transparent,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color.fromARGB(255, 85, 36, 74),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color.fromARGB(255, 92, 23, 86),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SizedBox(
        height: height * 0.85,
        child: VideoBackground(
          overlayColor: Colors.transparent,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    todo.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 250, 248, 250),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      infoCard('Status', status),
                      infoCard('Priority', priority),
                      infoCard('Category', category),
                      infoCard('Repeat', repeat),
                      infoCard('Important', important),
                      infoCard('Pinned', pinned),
                    ],
                  ),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF0F6), Color(0xFFF5EEFF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF493347),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  if (completionDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: infoCard('Completion Date', completionDate!),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          150,
                          209,
                          243,
                        ),
                        foregroundColor: const Color.fromARGB(255, 77, 5, 80),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
