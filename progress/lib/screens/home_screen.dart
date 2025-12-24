import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/progress_log.dart';
import '../models/goal.dart';
import '../services/supabase_database_service.dart';
import '../utils/helpers.dart';
import 'goal_detail_screen.dart';
import 'global_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService.instance;
  List<ProgressLog> _recentActivity = [];
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  Future<void> _loadRecentActivity() async {
    setState(() => _isLoading = true);
    final activity = await _db.getRecentActivity(limit: 50);
    // Load all goals for these activity items
    final goalIds = activity.map((log) => log.goalId).toSet();
    final goals = <Goal>[];
    for (final goalId in goalIds) {
      final goal = await _db.getGoal(goalId);
      if (goal != null) {
        goals.add(goal);
      }
    }
    setState(() {
      _recentActivity = activity;
      _goals = goals;
      _isLoading = false;
    });
  }

  List<ProgressLog> get _recentActivityList {
    return _recentActivity.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              GlobalSearchScreen.show(context);
            },
            tooltip: 'Search all goals and tasks',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              context.push('/long-term-goals').then((_) => _loadRecentActivity());
            },
            tooltip: 'Long Term Goals',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecentActivity,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Text(
                  'Welcome!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your skill development journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Quick actions grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.folder,
                      title: 'Long Term Goals',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        context.push('/long-term-goals').then((_) => _loadRecentActivity());
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.flag,
                      title: 'Short Term Goals',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () {
                        context.push('/short-term-goals').then((_) => _loadRecentActivity());
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Recent activity section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_recentActivity.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          context.push('/long-term-goals');
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent activity list
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_recentActivity.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No activity yet',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
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
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                context.push('/long-term-goals');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Get Started'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._recentActivityList.map((log) {
                    final goal = _goals.firstWhere(
                      (g) => g.id == log.goalId,
                      orElse: () => Goal(
                        id: '',
                        subSkillId: '',
                        title: 'Unknown Goal',
                        status: GoalStatus.notStarted,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.check_circle,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          goal.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              formatDate(log.date),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (log.notes != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                log.notes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (log.durationMinutes != null) ...[
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(
                                  formatDuration(log.durationMinutes!),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GoalDetailScreen(goal: goal),
                            ),
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
