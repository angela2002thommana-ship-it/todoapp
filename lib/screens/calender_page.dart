import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../utils/todo_utils.dart';
import '../widgets/video_background.dart';

class CalendarPage extends StatefulWidget {
  final List<Todo> todos;
  final List<Color> taskColors;
  final VoidCallback onChanged;

  const CalendarPage({
    super.key,
    required this.todos,
    required this.taskColors,
    required this.onChanged,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();

  List<Todo> get selectedTasks {
    return widget.todos.where((todo) {
      final date = todo.completionDate;

      return date != null &&
          date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;
    }).toList();
  }

  int workload() {
    return selectedTasks.fold(0, (sum, todo) => sum + todo.estimatedMinutes);
  }

  int columns(double width) {
    if (width < 500) return 2;
    if (width < 900) return 3;
    if (width < 1300) return 4;
    return 5;
  }

  double cardRatio(double width) {
    if (width < 500) return 1.05;
    if (width < 900) return 1.25;
    if (width < 1300) return 1.40;
    return 1.55;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tasks = selectedTasks;
    final taskColumns = columns(width);

    return VideoBackground(
      overlayColor: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Calender',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: CustomScrollView(
            key: const PageStorageKey('calendar_scroll'),
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    width < 500 ? 8 : 12,
                    8,
                    width < 500 ? 8 : 12,
                    0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFCE93D8),
                        onPrimary: Colors.white,
                        secondary: Color(0xFF80DEEA),
                        onSecondary: Colors.white,
                        surface: Colors.transparent,
                        onSurface: Colors.white,
                      ),
                      scaffoldBackgroundColor: Colors.transparent,
                      canvasColor: Colors.transparent,
                      textTheme: Theme.of(context).textTheme.apply(
                        bodyColor: Colors.white,
                        displayColor: Colors.white,
                      ),
                      iconTheme: const IconThemeData(color: Colors.white),
                      datePickerTheme: DatePickerThemeData(
                        backgroundColor: Colors.transparent,
                        headerBackgroundColor: Colors.transparent,
                        headerForegroundColor: Colors.white,
                        weekdayStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                        dayForegroundColor: const WidgetStatePropertyAll(
                          Colors.white,
                        ),
                        dayBackgroundColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        dayShape:
                            WidgetStateProperty.resolveWith<OutlinedBorder?>((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return const CircleBorder(
                                  side: BorderSide(
                                    color: Color(0xFFCE93D8),
                                    width: 2,
                                  ),
                                );
                              }

                              return const CircleBorder(
                                side: BorderSide(
                                  color: Colors.transparent,
                                  width: 2,
                                ),
                              );
                            }),
                        todayForegroundColor: const WidgetStatePropertyAll(
                          Colors.white,
                        ),
                        todayBackgroundColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        todayBorder: const BorderSide(
                          color: Color(0xFF80DEEA),
                          width: 2,
                        ),
                        yearForegroundColor: const WidgetStatePropertyAll(
                          Colors.white,
                        ),
                        surfaceTintColor: Colors.transparent,
                      ),
                      dialogTheme: const DialogThemeData(
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    child: CalendarDatePicker(
                      key: ValueKey('${selected.year}-${selected.month}'),
                      initialDate: selected,
                      currentDate: DateUtils.dateOnly(DateTime.now()),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) {
                        setState(() {
                          selected = date;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _stats(width)),
              if (tasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No tasks for this date',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    width < 500 ? 8 : 10,
                    4,
                    width < 500 ? 8 : 10,
                    24,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = tasks[index];
                      return _taskCard(task, width);
                    }, childCount: tasks.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: taskColumns,
                      crossAxisSpacing: width < 500 ? 6 : 8,
                      mainAxisSpacing: width < 500 ? 6 : 8,
                      childAspectRatio: cardRatio(width),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stats(double width) {
    final tasks = selectedTasks;
    final completed = tasks.where((t) => t.done).length;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width < 500 ? 8 : 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(child: _circularStat('Tasks', '${tasks.length}')),
          Expanded(child: _circularStat('Workload', formatMinutes(workload()))),
          Expanded(child: _circularStat('Completed', '$completed')),
        ],
      ),
    );
  }

  Widget _circularStat(String title, String value) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _taskCard(Todo task, double width) {
    final cardPadding = width < 500 ? 8.0 : 10.0;
    final titleSize = width < 500 ? 11.5 : 13.0;
    final smallSize = width < 500 ? 9.0 : 10.5;

    final color = widget.taskColors[task.colorIndex % widget.taskColors.length];

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.90),
            color.withValues(alpha: 0.62),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.done
              ? const Color(0xFF43A047)
              : Colors.white.withValues(alpha: 0.65),
          width: task.done ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF3B3355),
              fontWeight: FontWeight.bold,
              fontSize: titleSize,
              decoration: task.done ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText(task.completionDate!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF3B3355),
              fontSize: smallSize,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            formatMinutes(task.estimatedMinutes),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF3B3355),
              fontSize: smallSize,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: taskProgress(task),
            minHeight: 5,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 5),
          Text(
            task.done ? 'Completed' : 'Pending',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: smallSize,
              color: task.done
                  ? const Color.fromARGB(255, 102, 230, 111)
                  : const Color.fromARGB(255, 240, 52, 52),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget calendarStat(
    String title,
    String value, {
    double titleFontSize = 14,
    double valueFontSize = 22,
    FontWeight titleFontWeight = FontWeight.bold,
    FontWeight valueFontWeight = FontWeight.bold,
    Color textColor = const Color(0xFF1565C0),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: valueFontWeight,
              fontSize: valueFontSize,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: titleFontWeight,
              fontSize: titleFontSize,
            ),
          ),
        ],
      ),
    );
  }
}
