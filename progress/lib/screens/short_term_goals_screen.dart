import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/short_term_goal.dart';
import '../models/goal.dart';
import '../services/supabase_database_service.dart';
import '../utils/helpers.dart';
import 'global_search_screen.dart';
import '../widgets/breadcrumb_nav.dart';

class ShortTermGoalsScreen extends StatefulWidget {
  const ShortTermGoalsScreen({super.key});

  @override
  State<ShortTermGoalsScreen> createState() => _ShortTermGoalsScreenState();
}

class _ShortTermGoalsScreenState extends State<ShortTermGoalsScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService.instance;
  List<ShortTermGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await _db.getAllShortTermGoals();
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }


  Future<void> _addGoal() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    GoalDifficulty? selectedDifficulty;
    DateTime? selectedDueDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Short Term Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Goal title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GoalDifficulty>(
                  initialValue: selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<GoalDifficulty>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...GoalDifficulty.values.map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDifficulty = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date (optional)'),
                  trailing: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedDueDate = date;
                        });
                      }
                    },
                    child: Text(
                      selectedDueDate == null
                          ? 'Select date'
                          : '${selectedDueDate!.year}-${selectedDueDate!.month.toString().padLeft(2, '0')}-${selectedDueDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
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
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    'difficulty': selectedDifficulty,
                    'dueDate': selectedDueDate,
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      // Set order to the end of the list
      final maxOrder = _goals.isEmpty
          ? -1
          : _goals.map((g) => g.order).reduce((a, b) => a > b ? a : b);
      final goal = ShortTermGoal(
        id: generateId(),
        title: result['title'],
        description: result['description'],
        status: GoalStatus.inProgress,
        difficulty: result['difficulty'],
        dueDate: result['dueDate'],
        order: maxOrder + 1,
        createdAt: now,
        updatedAt: now,
      );
      try {
        await _db.createShortTermGoal(goal);
        _loadGoals();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving goal: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editGoal(ShortTermGoal goal) async {
    final titleController = TextEditingController(text: goal.title);
    final descriptionController = TextEditingController(
      text: goal.description ?? '',
    );
    GoalDifficulty? selectedDifficulty = goal.difficulty;
    DateTime? selectedDueDate = goal.dueDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Short Term Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Goal title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GoalDifficulty>(
                  initialValue: selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<GoalDifficulty>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...GoalDifficulty.values.map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDifficulty = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date (optional)'),
                  trailing: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedDueDate = date;
                        });
                      }
                    },
                    child: Text(
                      selectedDueDate == null
                          ? 'Select date'
                          : '${selectedDueDate!.year}-${selectedDueDate!.month.toString().padLeft(2, '0')}-${selectedDueDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
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
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    'difficulty': selectedDifficulty,
                    'dueDate': selectedDueDate,
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
      final updatedGoal = goal.copyWith(
        title: result['title'],
        description: result['description'],
        difficulty: result['difficulty'],
        dueDate: result['dueDate'],
        updatedAt: now,
      );
      try {
        await _db.updateShortTermGoal(updatedGoal);
        _loadGoals();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating goal: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteGoal(ShortTermGoal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Short Term Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
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
        await _db.deleteShortTermGoal(goal.id);
        _loadGoals();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting goal: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = _goals[oldIndex];
    setState(() {
      _goals.removeAt(oldIndex);
      _goals.insert(newIndex, item);
    });

    // Update order values for all goals that changed
    final now = DateTime.now();
    final int startIndex = oldIndex < newIndex ? oldIndex : newIndex;
    final int endIndex = oldIndex < newIndex ? newIndex : oldIndex;

    for (int i = startIndex; i <= endIndex; i++) {
      final goal = _goals[i];
      final updatedGoal = goal.copyWith(order: i, updatedAt: now);
      await _db.updateShortTermGoal(updatedGoal);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back to home',
        ),
        title: const Text('Short Term Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              GlobalSearchScreen.show(context);
            },
            tooltip: 'Search all goals and tasks',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addGoal,
            tooltip: 'Add goal',
          ),
        ],
      ),
      body: Column(
        children: [
          BreadcrumbNav(
            items: const [
              BreadcrumbItem(label: 'Home', route: '/'),
              BreadcrumbItem(label: 'Short Term Goals'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No short term goals yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first short term goal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  onReorder: _onReorder,
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 6,
                      color: Colors.transparent,
                      shadowColor: Theme.of(context).shadowColor,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return Card(
                      key: ValueKey(goal.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          goal.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (goal.description != null)
                              Text(
                                goal.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (goal.dueDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Due: ${goal.dueDate!.year}-${goal.dueDate!.month.toString().padLeft(2, '0')}-${goal.dueDate!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: goal.dueDate!.isBefore(DateTime.now())
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            if (goal.difficulty != null)
                              Row(
                                children: [
                                  Chip(
                                    label: Text(goal.difficulty!.displayName),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () {
                                Future.delayed(
                                  Duration.zero,
                                  () => _editGoal(goal),
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () {
                                Future.delayed(
                                  Duration.zero,
                                  () => _deleteGoal(goal),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          final result = await context.push('/short-term-goals/${goal.id}');
                          if (result == true || mounted) {
                            _loadGoals(); // Reload to show updated status
                          }
                        },
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

