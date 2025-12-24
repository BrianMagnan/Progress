import 'package:flutter/material.dart';
import '../models/short_term_goal.dart';
import '../models/goal.dart';
import '../models/daily_task.dart';
import '../services/supabase_database_service.dart';
import '../utils/helpers.dart';
import '../utils/notification_helper.dart';
import '../widgets/breadcrumb_nav.dart';

class ShortTermGoalDetailScreen extends StatefulWidget {
  final ShortTermGoal goal;

  const ShortTermGoalDetailScreen({super.key, required this.goal});

  @override
  State<ShortTermGoalDetailScreen> createState() => _ShortTermGoalDetailScreenState();
}

class _ShortTermGoalDetailScreenState extends State<ShortTermGoalDetailScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService.instance;
  late ShortTermGoal _goal;
  final bool _isLoading = false;
  List<DailyTask> _dailyTasks = [];
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadDailyTasks();
  }

  Future<void> _loadDailyTasks() async {
    setState(() => _isLoadingTasks = true);
    final tasks = await _db.getDailyTasksByGoal(_goal.id);
    setState(() {
      _dailyTasks = tasks;
      _isLoadingTasks = false;
    });
    // Schedule notifications for all tasks
    await NotificationHelper.scheduleDailyTaskReminders(_goal, tasks);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Short Term Goal'),
      ),
      body: Column(
        children: [
          BreadcrumbNav(
            items: [
              const BreadcrumbItem(label: 'Home', route: '/'),
              const BreadcrumbItem(label: 'Short Term Goals', route: '/short-term-goals'),
              BreadcrumbItem(label: widget.goal.title),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Title
                  Text(
                    _goal.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  if (_goal.description != null) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _goal.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Due Date
                  if (_goal.dueDate != null) ...[
                    Card(
                      color: _goal.dueDate!.isBefore(DateTime.now()) && _goal.status != GoalStatus.completed
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      child: ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: _goal.dueDate!.isBefore(DateTime.now()) && _goal.status != GoalStatus.completed
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : null,
                        ),
                        title: const Text('Due Date'),
                        subtitle: Text(
                          '${_goal.dueDate!.year}-${_goal.dueDate!.month.toString().padLeft(2, '0')}-${_goal.dueDate!.day.toString().padLeft(2, '0')}',
                        ),
                        trailing: _goal.dueDate!.isBefore(DateTime.now()) && _goal.status != GoalStatus.completed
                            ? Chip(
                                label: const Text('Overdue'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                                labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Difficulty
                  if (_goal.difficulty != null) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.trending_up),
                        title: const Text('Difficulty'),
                        subtitle: Text(_goal.difficulty!.displayName),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Daily Tasks Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Tasks',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addDailyTask,
                        tooltip: 'Add daily task',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isLoadingTasks)
                    const Center(child: CircularProgressIndicator())
                  else if (_dailyTasks.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No daily tasks yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add exercises or tasks for different days',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildDailyTasksList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDailyTasksList() {
    // Group tasks by name
    final tasksByName = <String, List<DailyTask>>{};
    for (final task in _dailyTasks) {
      tasksByName.putIfAbsent(task.taskName, () => []).add(task);
    }

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return tasksByName.entries.map((entry) {
      final taskName = entry.key;
      final tasks = entry.value;
      
      // Build subtitle with day information
      final dayInfo = tasks.map((task) {
        if (task.isDaily) {
          return 'Daily';
        } else if (task.specificDate != null) {
          return '${task.specificDate!.year}-${task.specificDate!.month.toString().padLeft(2, '0')}-${task.specificDate!.day.toString().padLeft(2, '0')}';
        } else if (task.dayOfWeek != null) {
          return days[task.dayOfWeek!];
        }
        return 'Unknown';
      }).join(', ');
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(
            Icons.fitness_center,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            taskName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(dayInfo),
          trailing: PopupMenuButton(
            itemBuilder: (context) {
              final items = <PopupMenuEntry<dynamic>>[];
              
              if (tasks.length == 1) {
                items.add(
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () {
                      Future.delayed(Duration.zero, () => _editDailyTask(tasks.first));
                    },
                  ),
                );
                items.add(
                  PopupMenuItem(
                    child: const Text('Delete'),
                    onTap: () {
                      Future.delayed(Duration.zero, () => _deleteDailyTask(tasks.first));
                    },
                  ),
                );
              } else {
                for (final task in tasks) {
                  items.add(
                    PopupMenuItem(
                      child: Text('Edit (${task.specificDate != null ? '${task.specificDate!.year}-${task.specificDate!.month.toString().padLeft(2, '0')}-${task.specificDate!.day.toString().padLeft(2, '0')}' : task.dayOfWeek != null ? days[task.dayOfWeek!] : 'Unknown'})'),
                      onTap: () {
                        Future.delayed(Duration.zero, () => _editDailyTask(task));
                      },
                    ),
                  );
                }
                items.add(const PopupMenuDivider());
                items.add(
                  PopupMenuItem(
                    child: const Text('Delete All'),
                    onTap: () {
                      Future.delayed(Duration.zero, () => _deleteAllTasksWithName(taskName));
                    },
                  ),
                );
              }
              
              return items;
            },
          ),
        ),
      );
    }).toList();
  }

  Future<void> _deleteAllTasksWithName(String taskName) async {
    final tasksToDelete = _dailyTasks.where((t) => t.taskName == taskName).toList();
    if (tasksToDelete.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Tasks'),
        content: Text('Are you sure you want to delete all "$taskName" tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Cancel notifications before deleting
        for (final task in tasksToDelete) {
          await NotificationHelper.cancelTaskReminders(task);
          await _db.deleteDailyTask(task.id);
        }
        await _loadDailyTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting tasks: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _addDailyTask() async {
    final nameController = TextEditingController();
    int? selectedDayOfWeek;
    DateTime? selectedSpecificDate;
    String? taskType; // null, 'daily', 'recurring', or 'specific'

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Daily Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Task name (e.g., Running, Push-ups)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                RadioGroup<String?>(
                  groupValue: taskType,
                  onChanged: (value) {
                    setDialogState(() {
                      taskType = value;
                      if (value == 'daily') {
                        selectedSpecificDate = null;
                        selectedDayOfWeek = null;
                      } else if (value == 'recurring') {
                        selectedSpecificDate = null;
                      } else if (value == 'specific') {
                        selectedDayOfWeek = null;
                      }
                    });
                  },
                  child: Column(
                    children: [
                      RadioListTile<String?>(
                        title: const Text('Daily (every day)'),
                        value: 'daily',
                      ),
                      RadioListTile<String?>(
                        title: const Text('Recurring weekly'),
                        value: 'recurring',
                      ),
                      RadioListTile<String?>(
                        title: const Text('Specific date'),
                        value: 'specific',
                      ),
                    ],
                  ),
                ),
                if (taskType == 'recurring') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Day of week',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ].asMap().entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDayOfWeek = value;
                      });
                    },
                  ),
                ] else if (taskType == 'specific') ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Specific Date (optional)'),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedSpecificDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedSpecificDate = date;
                            selectedDayOfWeek = null;
                          });
                        }
                      },
                      child: Text(
                        selectedSpecificDate == null
                            ? 'Select date'
                            : '${selectedSpecificDate!.year}-${selectedSpecificDate!.month.toString().padLeft(2, '0')}-${selectedSpecificDate!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  if (taskType == 'recurring' && selectedDayOfWeek == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a day of week')),
                    );
                    return;
                  }
                  final isDaily = taskType == 'daily';
                  final isRecurring = taskType == 'recurring';
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'dayOfWeek': selectedDayOfWeek,
                    'specificDate': selectedSpecificDate,
                    'isRecurring': isRecurring,
                    'isDaily': isDaily,
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      final maxOrder = _dailyTasks.isEmpty
          ? -1
          : _dailyTasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);
      final task = DailyTask(
        id: generateId(),
        shortTermGoalId: _goal.id,
        taskName: result['name'],
        dayOfWeek: result['dayOfWeek'],
        specificDate: result['specificDate'],
        isRecurring: result['isRecurring'] ?? false,
        isDaily: result['isDaily'] ?? false,
        order: maxOrder + 1,
        createdAt: now,
        updatedAt: now,
      );
      try {
        await _db.createDailyTask(task);
        await _loadDailyTasks();
        // Notifications are automatically scheduled in _loadDailyTasks
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving task: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editDailyTask(DailyTask task) async {
    final nameController = TextEditingController(text: task.taskName);
    int? selectedDayOfWeek = task.dayOfWeek;
    DateTime? selectedSpecificDate = task.specificDate;
    String? taskType;
    if (task.isDaily) {
      taskType = 'daily';
    } else if (task.isRecurring) {
      taskType = 'recurring';
    } else if (task.specificDate != null) {
      taskType = 'specific';
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Daily Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Task name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                RadioGroup<String?>(
                  groupValue: taskType,
                  onChanged: (value) {
                    setDialogState(() {
                      taskType = value;
                      if (value == 'daily') {
                        selectedSpecificDate = null;
                        selectedDayOfWeek = null;
                      } else if (value == 'recurring') {
                        selectedSpecificDate = null;
                      } else if (value == 'specific') {
                        selectedDayOfWeek = null;
                      }
                    });
                  },
                  child: Column(
                    children: [
                      RadioListTile<String?>(
                        title: const Text('Daily (every day)'),
                        value: 'daily',
                      ),
                      RadioListTile<String?>(
                        title: const Text('Recurring weekly'),
                        value: 'recurring',
                      ),
                      RadioListTile<String?>(
                        title: const Text('Specific date'),
                        value: 'specific',
                      ),
                    ],
                  ),
                ),
                if (taskType == 'recurring') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDayOfWeek,
                    decoration: const InputDecoration(
                      labelText: 'Day of week',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ].asMap().entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDayOfWeek = value;
                      });
                    },
                  ),
                ] else if (taskType == 'specific') ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Specific Date (optional)'),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedSpecificDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedSpecificDate = date;
                            selectedDayOfWeek = null;
                          });
                        }
                      },
                      child: Text(
                        selectedSpecificDate == null
                            ? 'Select date'
                            : '${selectedSpecificDate!.year}-${selectedSpecificDate!.month.toString().padLeft(2, '0')}-${selectedSpecificDate!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  if (taskType == 'recurring' && selectedDayOfWeek == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a day of week')),
                    );
                    return;
                  }
                  final isDaily = taskType == 'daily';
                  final isRecurring = taskType == 'recurring';
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'dayOfWeek': selectedDayOfWeek,
                    'specificDate': selectedSpecificDate,
                    'isRecurring': isRecurring,
                    'isDaily': isDaily,
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      final updatedTask = task.copyWith(
        taskName: result['name'],
        dayOfWeek: result['dayOfWeek'],
        specificDate: result['specificDate'],
        isRecurring: result['isRecurring'] ?? false,
        isDaily: result['isDaily'] ?? false,
        updatedAt: now,
      );
      try {
        // Cancel old notification before updating
        await NotificationHelper.cancelTaskReminders(task);
        await _db.updateDailyTask(updatedTask);
        await _loadDailyTasks();
        // Notifications are automatically rescheduled in _loadDailyTasks
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating task: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteDailyTask(DailyTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Daily Task'),
        content: Text('Are you sure you want to delete "${task.taskName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Cancel notification before deleting
        await NotificationHelper.cancelTaskReminders(task);
        await _db.deleteDailyTask(task.id);
        await _loadDailyTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting task: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

