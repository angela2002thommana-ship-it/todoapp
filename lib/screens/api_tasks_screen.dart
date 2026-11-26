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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Firebase Tasks'),
        actions: [
          IconButton(
            onPressed: isLoading || isBusy ? null : () => fetchTodos(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tasks',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null && todos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => fetchTodos(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (todos.isEmpty) {
            return const Center(child: Text('No tasks found in Firebase.'));
          }

          final visibleTodos = filteredTodos;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ApiTaskFilter>(
                        value: selectedFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Filter',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: ApiTaskFilter.values.map((filter) {
                          return DropdownMenuItem<ApiTaskFilter>(
                            value: filter,
                            child: Text(
                              filterLabel(filter),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ApiTaskSort>(
                        value: selectedSort,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: ApiTaskSort.values.map((sort) {
                          return DropdownMenuItem<ApiTaskSort>(
                            value: sort,
                            child: Text(sortLabel(sort)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedSort = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${visibleTodos.length} of ${todos.length} tasks',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: visibleTodos.isEmpty
                    ? const Center(child: Text('No tasks match this filter.'))
                    : ListView.builder(
                        itemCount: visibleTodos.length,
                        itemBuilder: (context, index) {
                          final todo = visibleTodos[index];

                          return ListTile(
                            leading: Checkbox(
                              value: todo.done,
                              onChanged: isBusy
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        toggleTodoStatus(todo, value);
                                      }
                                    },
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            subtitle: Text(
                              '${todo.category.name} • ${todo.priority.name} priority',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => toggleTodoFlag(
                                          todo,
                                          isImportant: false,
                                        ),
                                  icon: Icon(
                                    todo.pinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    color: todo.pinned ? Colors.blue : null,
                                  ),
                                  tooltip: todo.pinned
                                      ? 'Unpin task'
                                      : 'Pin task',
                                ),
                                IconButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => editTodo(todo),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit task',
                                ),
                                IconButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => deleteTodo(todo),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete task',
                                ),
                                IconButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => toggleTodoFlag(
                                          todo,
                                          isImportant: true,
                                        ),
                                  icon: Icon(
                                    todo.important
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: todo.important ? Colors.amber : null,
                                  ),
                                  tooltip: todo.important
                                      ? 'Remove importance'
                                      : 'Mark important',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isBusy ? null : createTodo,
        icon: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(
          isCreating
              ? 'Creating...'
              : isUpdating
              ? 'Updating...'
              : isDeleting
              ? 'Deleting...'
              : 'Add API Task',
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
