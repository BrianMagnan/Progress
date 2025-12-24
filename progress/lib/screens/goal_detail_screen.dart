import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/progress_log.dart';
import '../models/sub_skill.dart';
import '../models/skill.dart';
import '../models/category.dart';
import '../services/supabase_database_service.dart';
import '../utils/helpers.dart';
import '../widgets/breadcrumb_nav.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService.instance;
  List<ProgressLog> _logs = [];
  ProgressLog? _latestLog;
  SubSkill? _subSkill;
  Skill? _skill;
  Category? _category;
  bool _isLoading = true;
  int _totalSessions = 0;
  int _totalMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final logs = await _db.getProgressLogsByGoal(widget.goal.id);
    final latest = await _db.getLatestProgressLog(widget.goal.id);
    final sessions = await _db.getTotalProgressLogsCount(widget.goal.id);
    final minutes = await _db.getTotalDurationMinutes(widget.goal.id);
    final subSkill = await _db.getSubSkill(widget.goal.subSkillId);
    Skill? skill;
    Category? category;
    if (subSkill != null) {
      skill = await _db.getSkill(subSkill.skillId);
      if (skill != null) {
        category = await _db.getCategory(skill.categoryId);
      }
    }

    setState(() {
      _logs = logs;
      _latestLog = latest;
      _totalSessions = sessions;
      _totalMinutes = minutes;
      _subSkill = subSkill;
      _skill = skill;
      _category = category;
      _isLoading = false;
    });
  }

  Future<void> _addProgressLog() async {
    final notesController = TextEditingController();
    final learnedController = TextEditingController();
    final struggledController = TextEditingController();
    final nextStepsController = TextEditingController();
    final durationController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log Progress'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  trailing: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What you practiced',
                    border: OutlineInputBorder(),
                    hintText: 'Describe what you worked on...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: learnedController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What you learned',
                    border: OutlineInputBorder(),
                    hintText: 'Key insights or breakthroughs...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: struggledController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What you struggled with',
                    border: OutlineInputBorder(),
                    hintText: 'Challenges or areas of difficulty...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nextStepsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What you want to do next',
                    border: OutlineInputBorder(),
                    hintText: 'Your plan for the next session...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes, optional)',
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
                final duration = durationController.text.trim().isEmpty
                    ? null
                    : int.tryParse(durationController.text.trim());
                Navigator.pop(context, {
                  'date': selectedDate,
                  'notes': notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                  'learned': learnedController.text.trim().isEmpty
                      ? null
                      : learnedController.text.trim(),
                  'struggled': struggledController.text.trim().isEmpty
                      ? null
                      : struggledController.text.trim(),
                  'nextSteps': nextStepsController.text.trim().isEmpty
                      ? null
                      : nextStepsController.text.trim(),
                  'duration': duration,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      final log = ProgressLog(
        id: generateId(),
        goalId: widget.goal.id,
        date: result['date'],
        notes: result['notes'],
        learned: result['learned'],
        struggledWith: result['struggled'],
        nextSteps: result['nextSteps'],
        durationMinutes: result['duration'],
        createdAt: now,
      );
      await _db.createProgressLog(log);

      // Update goal status to in progress if it was not started
      if (widget.goal.status == GoalStatus.notStarted) {
        final updatedGoal = widget.goal.copyWith(
          status: GoalStatus.inProgress,
          updatedAt: now,
        );
        await _db.updateGoal(updatedGoal);
      }

      _loadData();
      if (mounted) {
        setState(() {}); // Refresh goal status
      }
    }
  }

  Future<void> _updateGoalStatus(GoalStatus newStatus) async {
    final now = DateTime.now();
    final updatedGoal = widget.goal.copyWith(
      status: newStatus,
      updatedAt: now,
      completedAt: newStatus == GoalStatus.completed
          ? now
          : widget.goal.completedAt,
    );
    await _db.updateGoal(updatedGoal);
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate update
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
      appBar: AppBar(
        title: Text(widget.goal.title),
        actions: [
          PopupMenuButton<GoalStatus>(
            icon: const Icon(Icons.more_vert),
            onSelected: _updateGoalStatus,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: GoalStatus.notStarted,
                enabled: widget.goal.status != GoalStatus.notStarted,
                child: const Text('Not Started'),
              ),
              PopupMenuItem(
                value: GoalStatus.inProgress,
                enabled: widget.goal.status != GoalStatus.inProgress,
                child: const Text('In Progress'),
              ),
              PopupMenuItem(
                value: GoalStatus.completed,
                enabled: widget.goal.status != GoalStatus.completed,
                child: const Text('Completed'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          BreadcrumbNav(
            items: _skill != null && _subSkill != null && _category != null
                ? [
                    const BreadcrumbItem(label: 'Home', route: '/'),
                    const BreadcrumbItem(label: 'Long Term Goals', route: '/long-term-goals'),
                    BreadcrumbItem(
                      label: _category!.name,
                      route: '/long-term-goals/${_category!.id}',
                    ),
                    BreadcrumbItem(
                      label: _skill!.name,
                      route: '/long-term-goals/${_skill!.categoryId}/skills/${_skill!.id}',
                    ),
                    BreadcrumbItem(
                      label: _subSkill!.name,
                      route: '/long-term-goals/${_skill!.categoryId}/skills/${_skill!.id}/sub-skills/${_subSkill!.id}',
                    ),
                    BreadcrumbItem(label: widget.goal.title),
                  ]
                : [
                    const BreadcrumbItem(label: 'Home', route: '/'),
                    const BreadcrumbItem(label: 'Long Term Goals', route: '/long-term-goals'),
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
                  // Goal Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    widget.goal.status,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.goal.status.displayName,
                                  style: TextStyle(
                                    color: _getStatusColor(widget.goal.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.goal.difficulty != null) ...[
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    widget.goal.difficulty!.displayName,
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ],
                          ),
                          if (widget.goal.description != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              widget.goal.description!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                          if (widget.goal.estimatedHours != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Estimated: ${widget.goal.estimatedHours} hours',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Statistics
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '$_totalSessions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sessions',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  _totalMinutes > 0
                                      ? formatDuration(_totalMinutes)
                                      : '0 min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total Time',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Last Session Summary (Context Recovery)
                  if (_latestLog != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Last Session',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formatDate(_latestLog!.date),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (_latestLog!.notes != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow('Practiced', _latestLog!.notes!),
                            ],
                            if (_latestLog!.learned != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow('Learned', _latestLog!.learned!),
                            ],
                            if (_latestLog!.struggledWith != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Struggled with',
                                _latestLog!.struggledWith!,
                              ),
                            ],
                            if (_latestLog!.nextSteps != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Next steps',
                                _latestLog!.nextSteps!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Progress Logs
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress Logs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_logs.length} entries',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_logs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No progress logs yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start tracking your progress to see it here',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._logs.map(
                      (log) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatDate(log.date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  if (log.durationMinutes != null)
                                    Chip(
                                      label: Text(
                                        formatDuration(log.durationMinutes!),
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                              if (log.notes != null) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow('Practiced', log.notes!),
                              ],
                              if (log.learned != null) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow('Learned', log.learned!),
                              ],
                              if (log.struggledWith != null) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  'Struggled with',
                                  log.struggledWith!,
                                ),
                              ],
                              if (log.nextSteps != null) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow('Next steps', log.nextSteps!),
                              ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProgressLog,
        icon: const Icon(Icons.add),
        label: const Text('Log Progress'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
