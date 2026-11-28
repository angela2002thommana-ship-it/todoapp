import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../services/api_service.dart';

enum ApiTaskFilter {
  all,
  pending,
  completed,
  important,
  pinned,
  high,
  medium,
  low,
}

enum ApiTaskSort { newest, alphabetical, priority }

class ApiTasksScreen extends StatefulWidget {
  const ApiTasksScreen({super.key});

  @override
  State<ApiTasksScreen> createState() => _ApiTasksScreenState();
}

class _ApiTasksScreenState extends State<ApiTasksScreen> {
  final ApiService apiService = ApiService();

  List<Todo> todos = [];

  bool isLoading = true;
  bool isCreating = false;
  bool isUpdating = false;
  bool isDeleting = false;

  String? errorMessage;

  ApiTaskFilter selectedFilter = ApiTaskFilter.all;
  ApiTaskSort selectedSort = ApiTaskSort.newest;

  bool get isBusy => isCreating || isUpdating || isDeleting;

  List<Todo> get filteredTodos {
    final result = todos.where((todo) {
      switch (selectedFilter) {
        case ApiTaskFilter.all:
          return true;
        case ApiTaskFilter.pending:
          return !todo.done;
        case ApiTaskFilter.completed:
          return todo.done;
        case ApiTaskFilter.important:
          return todo.important;
        case ApiTaskFilter.pinned:
          return todo.pinned;
        case ApiTaskFilter.high:
          return todo.priority == Priority.high;
        case ApiTaskFilter.medium:
          return todo.priority == Priority.medium;
        case ApiTaskFilter.low:
          return todo.priority == Priority.low;
      }
    }).toList();

    switch (selectedSort) {
      case ApiTaskSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ApiTaskSort.alphabetical:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case ApiTaskSort.priority:
        result.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
    }

    return result;
  }

  String filterLabel(ApiTaskFilter filter) {
    switch (filter) {
      case ApiTaskFilter.all:
        return 'All';
      case ApiTaskFilter.pending:
        return 'Pending';
      case ApiTaskFilter.completed:
        return 'Completed';
      case ApiTaskFilter.important:
        return 'Important';
      case ApiTaskFilter.pinned:
        return 'Pinned';
      case ApiTaskFilter.high:
        return 'High priority';
      case ApiTaskFilter.medium:
        return 'Medium priority';
      case ApiTaskFilter.low:
        return 'Low priority';
    }
  }

  String sortLabel(ApiTaskSort sort) {
    switch (sort) {
      case ApiTaskSort.newest:
        return 'Newest';
      case ApiTaskSort.alphabetical:
        return 'Alphabetical';
      case ApiTaskSort.priority:
        return 'Priority';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  Future<bool> fetchTodos({bool showLoader = true}) async {
    if (!mounted) return false;

    setState(() {
      if (showLoader) {
        isLoading = true;
      }
      errorMessage = null;
    });

    try {
      final result = await apiService.fetchTodos();

      if (!mounted) return false;

      setState(() {
        todos = result;
        isLoading = false;
        errorMessage = null;
      });

      return true;
    } catch (error) {
      if (!mounted) return false;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });

      return false;
    }
  }

  Future<void> createTodo() async {
    if (isBusy) return;

    final newTodo = await showDialog<Todo>(
      context: context,
      builder: (_) => const _TodoEditorDialog(),
    );

    if (!mounted || newTodo == null) return;

    setState(() {
      isCreating = true;
    });

    try {
      await apiService.createTodo(newTodo);

      if (!mounted) return;

      final refreshed = await fetchTodos(showLoader: false);

      if (!mounted) return;

      if (!refreshed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task created, but refreshing the list failed: $errorMessage',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
    }
  }

  Future<void> editTodo(Todo todo) async {
    if (isBusy) return;

    final updatedTodo = await showDialog<Todo>(
      context: context,
      builder: (_) => _TodoEditorDialog(todo: todo),
    );

    if (!mounted || updatedTodo == null) return;

    setState(() {
      isUpdating = true;
    });

    try {
      await apiService.updateTodo(updatedTodo);

      if (!mounted) return;

      final refreshed = await fetchTodos(showLoader: false);

      if (!mounted) return;

      if (!refreshed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task updated, but refreshing the list failed: $errorMessage',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Future<void> deleteTodo(Todo todo) async {
    if (isBusy) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task?'),
          content: Text(
            'Are you sure you want to delete "${todo.title}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) return;

    setState(() {
      isDeleting = true;
    });

    try {
      await apiService.deleteTodo(todo.id);

      if (!mounted) return;

      final refreshed = await fetchTodos(showLoader: false);

      if (!mounted) return;

      if (!refreshed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task deleted, but refreshing failed: $errorMessage'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  Future<void> toggleTodoStatus(Todo todo, bool newValue) async {
    if (isBusy) return;

    final now = DateTime.now();

    int updatedTrackedSeconds = todo.trackedSeconds;
    DateTime? updatedTimerStartedAt = todo.timerStartedAt;

    DateTime? updatedCompletionDate;

    if (newValue) {
      updatedCompletionDate = now;

      if (updatedTimerStartedAt != null) {
        final elapsed = now.difference(updatedTimerStartedAt).inSeconds;

        if (elapsed > 0) {
          updatedTrackedSeconds += elapsed;
        }

        updatedTimerStartedAt = null;
      }
    } else {
      updatedCompletionDate = null;
    }

    final updatedTodo = Todo.fromJson({
      ...todo.toJson(),
      'done': newValue,
      'actualCompletionDate': updatedCompletionDate?.toIso8601String(),
      'trackedSeconds': updatedTrackedSeconds,
      'timerStartedAt': updatedTimerStartedAt?.toIso8601String(),
    });

    setState(() {
      isUpdating = true;
    });

    try {
      await apiService.updateTodo(updatedTodo);

      if (!mounted) return;

      final refreshed = await fetchTodos(showLoader: false);

      if (!mounted) return;

      if (!refreshed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated, but refreshing failed: $errorMessage',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? 'Task completed successfully!'
                : 'Task moved back to pending!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task status: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Future<void> toggleTodoFlag(Todo todo, {required bool isImportant}) async {
    if (isBusy) return;

    final newValue = isImportant ? !todo.important : !todo.pinned;

    final updatedTodo = Todo.fromJson({
      ...todo.toJson(),
      if (isImportant) 'important': newValue,
      if (!isImportant) 'pinned': newValue,
    });

    setState(() {
      isUpdating = true;
    });

    try {
      await apiService.updateTodo(updatedTodo);

      if (!mounted) return;

      final refreshed = await fetchTodos(showLoader: false);

      if (!mounted) return;

      if (!refreshed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isImportant ? 'Importance' : 'Pin'} updated, '
              'but refreshing failed: $errorMessage',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isImportant
                ? (newValue
                      ? 'Task marked as important!'
                      : 'Task removed from important!')
                : (newValue ? 'Task pinned!' : 'Task unpinned!'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update ${isImportant ? 'importance' : 'pin'}: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleTodos = filteredTodos;
    final completedCount = todos.where((todo) => todo.done).length;
    final pendingCount = todos.length - completedCount;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F8FC),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Tasks',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              'Manage your cloud tasks',
              style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
            ),
          ],
        ),
        actions: [
          if (isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            onPressed: isLoading || isBusy ? null : () => fetchTodos(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh tasks',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF168FCB)),
            )
          : errorMessage != null && todos.isEmpty
          ? _ApiEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load tasks',
              message: errorMessage!,
              actionLabel: 'Try again',
              onAction: () => fetchTodos(),
            )
          : todos.isEmpty
          ? _ApiEmptyState(
              icon: Icons.checklist_rounded,
              title: 'Your task space is empty',
              message:
                  'Create your first API task and start organizing your day.',
              actionLabel: 'Create a task',
              onAction: createTodo,
            )
          : RefreshIndicator(
              color: const Color(0xFF168FCB),
              onRefresh: () => fetchTodos(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _ApiWelcomeCard(
                    total: todos.length,
                    completed: completedCount,
                    pending: pendingCount,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Your overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF18344A),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.cloud_done_rounded,
                        size: 16,
                        color: Color(0xFF159B78),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Cloud connected',
                        style: TextStyle(
                          color: Color(0xFF159B78),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ApiStatCard(
                          label: 'Total',
                          count: todos.length,
                          icon: Icons.layers_rounded,
                          color: const Color(0xFF258BCB),
                          background: const Color(0xFFE5F4FC),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _ApiStatCard(
                          label: 'Pending',
                          count: pendingCount,
                          icon: Icons.schedule_rounded,
                          color: const Color(0xFFD58B22),
                          background: const Color(0xFFFFF4E3),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _ApiStatCard(
                          label: 'Completed',
                          count: completedCount,
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFF159B70),
                          background: const Color(0xFFE4F7EF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        'My tasks',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF18344A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F3FC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${visibleTodos.length}',
                          style: const TextStyle(
                            color: Color(0xFF147EBA),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<ApiTaskSort>(
                        tooltip: 'Sort tasks',
                        initialValue: selectedSort,
                        onSelected: (value) =>
                            setState(() => selectedSort = value),
                        itemBuilder: (context) => ApiTaskSort.values
                            .map(
                              (sort) => PopupMenuItem<ApiTaskSort>(
                                value: sort,
                                child: Row(
                                  children: [
                                    Icon(
                                      sort == selectedSort
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 17,
                                      color: const Color(0xFF168FCB),
                                    ),
                                    const SizedBox(width: 9),
                                    Text(sortLabel(sort)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCEAF2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sort_rounded,
                                size: 17,
                                color: Color(0xFF34718F),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                sortLabel(selectedSort),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF34718F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 39,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ApiTaskFilter.values.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = ApiTaskFilter.values[index];
                        final selected = selectedFilter == filter;
                        return ChoiceChip(
                          label: Text(filterLabel(filter)),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => selectedFilter = filter),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF567184),
                          ),
                          selectedColor: const Color(0xFF168FCB),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF168FCB)
                                : const Color(0xFFDCEAF2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFB86B16),
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'The task action succeeded, but the list could not refresh.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8B571D),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => fetchTodos(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  if (visibleTodos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 35),
                      child: _ApiEmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        title: 'No matching tasks',
                        message: 'Try another filter to see your tasks.',
                        actionLabel: 'Show all',
                        onAction: () =>
                            setState(() => selectedFilter = ApiTaskFilter.all),
                      ),
                    )
                  else
                    ...visibleTodos.map(
                      (todo) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _ApiTaskCard(
                          todo: todo,
                          isBusy: isBusy,
                          onStatusChanged: (value) =>
                              toggleTodoStatus(todo, value),
                          onPin: () => toggleTodoFlag(todo, isImportant: false),
                          onImportant: () =>
                              toggleTodoFlag(todo, isImportant: true),
                          onEdit: () => editTodo(todo),
                          onDelete: () => deleteTodo(todo),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isBusy ? null : createTodo,
        backgroundColor: const Color(0xFF168FCB),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: isBusy
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(
          isCreating
              ? 'Creating...'
              : isUpdating
              ? 'Updating...'
              : isDeleting
              ? 'Deleting...'
              : 'Add API Task',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ApiWelcomeCard extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;

  const _ApiWelcomeCard({
    required this.total,
    required this.completed,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF126FA8), Color(0xFF20B7C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF168FCB).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -22,
            child: Icon(
              Icons.waves_rounded,
              size: 125,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STAY ON TOP OF YOUR DAY',
                style: TextStyle(
                  color: Color(0xFFD8F6FF),
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Your tasks,\nin one place.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFB8F5E2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$completed completed  •  $pending remaining  •  $total total',
                style: const TextStyle(
                  color: Color(0xFFE2F8FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApiStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color background;

  const _ApiStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiTaskCard extends StatelessWidget {
  final Todo todo;
  final bool isBusy;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback onPin;
  final VoidCallback onImportant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ApiTaskCard({
    required this.todo,
    required this.isBusy,
    required this.onStatusChanged,
    required this.onPin,
    required this.onImportant,
    required this.onEdit,
    required this.onDelete,
  });

  Color get priorityColor {
    switch (todo.priority) {
      case Priority.high:
        return const Color(0xFFD95757);
      case Priority.medium:
        return const Color(0xFFD28A25);
      case Priority.low:
        return const Color(0xFF259B78);
      case Priority.none:
        return const Color(0xFF718096);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: todo.done ? 0.72 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: todo.done
                ? const Color(0xFFDDEBE7)
                : const Color(0xFFE1EDF3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF31566D).withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Checkbox(
                    value: todo.done,
                    onChanged: isBusy
                        ? null
                        : (value) {
                            if (value != null) onStatusChanged(value);
                          },
                    activeColor: const Color(0xFF159B78),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            color: const Color(0xFF20394B),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: todo.done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (todo.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            todo.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7A8D9A),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !isBusy,
                  tooltip: 'Task actions',
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF718797),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'pin':
                        onPin();
                        break;
                      case 'important':
                        onImportant();
                        break;
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: _ApiMenuItem(
                        icon: todo.pinned
                            ? Icons.push_pin_outlined
                            : Icons.push_pin_rounded,
                        label: todo.pinned ? 'Unpin task' : 'Pin task',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'important',
                      child: _ApiMenuItem(
                        icon: todo.important
                            ? Icons.star_outline_rounded
                            : Icons.star_rounded,
                        label: todo.important
                            ? 'Remove importance'
                            : 'Mark important',
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'edit',
                      child: _ApiMenuItem(
                        icon: Icons.edit_outlined,
                        label: 'Edit task',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: _ApiMenuItem(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete task',
                        color: Color(0xFFD9534F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 5),
              child: Wrap(
                spacing: 7,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ApiTag(
                    label:
                        todo.category.name[0].toUpperCase() +
                        todo.category.name.substring(1),
                    color: const Color(0xFF258BCB),
                    background: const Color(0xFFEAF6FC),
                  ),
                  _ApiTag(
                    label: todo.priority.name == 'none'
                        ? 'No priority'
                        : '${todo.priority.name[0].toUpperCase()}${todo.priority.name.substring(1)} priority',
                    color: priorityColor,
                    background: priorityColor.withValues(alpha: 0.10),
                  ),
                  if (todo.pinned)
                    const Icon(
                      Icons.push_pin_rounded,
                      size: 14,
                      color: Color(0xFF258BCB),
                    ),
                  if (todo.important)
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: Color(0xFFE2A52E),
                    ),
                  if (todo.done)
                    const _ApiTag(
                      label: 'Completed',
                      color: Color(0xFF159B78),
                      background: Color(0xFFE5F6EF),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _ApiTag({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ApiMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ApiMenuItem({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF526B7B),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

class _ApiEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _ApiEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F4FC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: const Color(0xFF168FCB)),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF20394B),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF718797),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 17),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF168FCB),
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoEditorDialog extends StatefulWidget {
  final Todo? todo;

  const _TodoEditorDialog({this.todo});

  @override
  State<_TodoEditorDialog> createState() => _TodoEditorDialogState();
}

class _TodoEditorDialogState extends State<_TodoEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  late Priority selectedPriority;
  late Category selectedCategory;
  late bool isImportant;
  late bool isPinned;

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.todo?.title ?? '');
    descriptionController = TextEditingController(
      text: widget.todo?.description ?? '',
    );
    selectedPriority = widget.todo?.priority ?? Priority.none;
    selectedCategory = widget.todo?.category ?? Category.other;
    isImportant = widget.todo?.important ?? false;
    isPinned = widget.todo?.pinned ?? false;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String enumLabel(String value) {
    return value[0].toUpperCase() + value.substring(1);
  }

  void saveTodo() {
    if (!formKey.currentState!.validate()) return;

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    final result = widget.todo == null
        ? Todo(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            description: description,
            priority: selectedPriority,
            category: selectedCategory,
            important: isImportant,
            pinned: isPinned,
          )
        : Todo.fromJson({
            ...widget.todo!.toJson(),
            'title': title,
            'description': description,
            'priority': selectedPriority.name,
            'category': selectedCategory.name,
            'important': isImportant,
            'pinned': isPinned,
          });

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit API Task' : 'Create API Task'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: Priority.values.map((priority) {
                  return DropdownMenuItem<Priority>(
                    value: priority,
                    child: Text(enumLabel(priority.name)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedPriority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: Category.values.map((category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(enumLabel(category.name)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Important'),
                value: isImportant,
                onChanged: (value) {
                  setState(() {
                    isImportant = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pinned'),
                value: isPinned,
                onChanged: (value) {
                  setState(() {
                    isPinned = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: saveTodo,
          child: Text(isEditing ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
