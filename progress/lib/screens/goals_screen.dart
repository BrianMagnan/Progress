import 'package:flutter/material.dart';
import '../models/sub_skill.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatefulWidget {
  final SubSkill subSkill;

  const GoalsScreen({super.key, required this.subSkill});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await _db.getGoalsBySubSkill(widget.subSkill.id);
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  Future<void> _addGoal() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final hoursController = TextEditingController();
    GoalDifficulty? selectedDifficulty;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Goal'),
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
                  items: GoalDifficulty.values.map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDifficulty = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimated hours (optional)',
                    border: OutlineInputBorder(),
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
                  final hours = hoursController.text.trim().isEmpty
                      ? null
                      : int.tryParse(hoursController.text.trim());
                  Navigator.pop(context, {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    'difficulty': selectedDifficulty,
                    'hours': hours,
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
      final goal = Goal(
        id: generateId(),
        subSkillId: widget.subSkill.id,
        title: result['title'],
        description: result['description'],
        status: GoalStatus.notStarted,
        difficulty: result['difficulty'],
        estimatedHours: result['hours'],
        createdAt: now,
        updatedAt: now,
      );
      await _db.createGoal(goal);
      _loadGoals();
    }
  }

  Color _getStatusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.notStarted:
        return Colors.grey;
      case GoalStatus.inProgress:
        return Colors.blue;
      case GoalStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subSkill.name)),
      body: _isLoading
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
                    'No goals yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first goal for ${widget.subSkill.name}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          goal.status,
                        ).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        goal.status == GoalStatus.completed
                            ? Icons.check_circle
                            : goal.status == GoalStatus.inProgress
                            ? Icons.play_circle
                            : Icons.radio_button_unchecked,
                        color: _getStatusColor(goal.status),
                      ),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(goal.status.displayName),
                              backgroundColor: _getStatusColor(
                                goal.status,
                              ).withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: _getStatusColor(goal.status),
                                fontSize: 12,
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            if (goal.difficulty != null) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(goal.difficulty!.displayName),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoalDetailScreen(goal: goal),
                        ),
                      );
                      if (result == true || mounted) {
                        _loadGoals(); // Reload to show updated status
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGoal,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }
}
