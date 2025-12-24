import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/goal.dart';
import '../models/daily_task.dart';
import '../models/sub_skill.dart';
import '../models/short_term_goal.dart';
import '../models/skill.dart';
import '../models/category.dart';
import '../services/supabase_database_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GlobalSearchScreen(),
    );
  }
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Goal> _allGoals = [];
  List<DailyTask> _allDailyTasks = [];
  List<Category> _allCategories = [];
  List<Skill> _allSkills = [];
  List<SubSkill> _allSubSkills = [];
  Map<String, SubSkill> _subSkills = {};
  Map<String, Skill> _skills = {};
  Map<String, Category> _categories = {};
  Map<String, ShortTermGoal> _shortTermGoals = {};
  List<Goal> _recentGoals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      // Load all goals and daily tasks
      final goals = await _db.getAllGoals();
      final dailyTasks = await _db.getAllDailyTasks();

      // Load all categories
      final allCategories = await _db.getAllCategories();

      // Load all skills and sub-skills
      final allSkills = <Skill>[];
      final allSubSkills = <SubSkill>[];
      final subSkills = <String, SubSkill>{};
      final skills = <String, Skill>{};
      final categories = <String, Category>{};

      for (final category in allCategories) {
        categories[category.id] = category;
        final categorySkills = await _db.getSkillsByCategory(category.id);
        allSkills.addAll(categorySkills);

        for (final skill in categorySkills) {
          skills[skill.id] = skill;
          final skillSubSkills = await _db.getSubSkillsBySkill(skill.id);
          allSubSkills.addAll(skillSubSkills);

          for (final subSkill in skillSubSkills) {
            subSkills[subSkill.id] = subSkill;
          }
        }
      }

      // Load all short-term goals for context
      final shortTermGoalIds = dailyTasks.map((t) => t.shortTermGoalId).toSet();
      final shortTermGoals = <String, ShortTermGoal>{};
      for (final goalId in shortTermGoalIds) {
        final goal = await _db.getShortTermGoal(goalId);
        if (goal != null) {
          shortTermGoals[goalId] = goal;
        }
      }

      // Load recent activity to show recent goals
      final recentActivity = await _db.getRecentActivity(limit: 10);
      final recentGoalIds = recentActivity.map((log) => log.goalId).toSet();
      final recentGoals = <Goal>[];
      for (final goalId in recentGoalIds) {
        final goal = await _db.getGoal(goalId);
        if (goal != null) {
          recentGoals.add(goal);
        }
      }

      setState(() {
        _allGoals = goals;
        _allDailyTasks = dailyTasks;
        _allCategories = allCategories;
        _allSkills = allSkills;
        _allSubSkills = allSubSkills;
        _subSkills = subSkills;
        _skills = skills;
        _categories = categories;
        _shortTermGoals = shortTermGoals;
        _recentGoals = recentGoals;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading search data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Goal> get _filteredGoals {
    if (_searchController.text.isEmpty) return [];
    final query = _searchController.text.toLowerCase();
    return _allGoals.where((goal) {
      // Search in goal title and description
      final titleMatch = goal.title.toLowerCase().contains(query);
      final descriptionMatch =
          goal.description?.toLowerCase().contains(query) ?? false;

      // Search in sub-skill name
      final subSkill = _subSkills[goal.subSkillId];
      final subSkillMatch =
          subSkill?.name.toLowerCase().contains(query) ?? false;

      // Search in skill name
      final skill = subSkill != null ? _skills[subSkill.skillId] : null;
      final skillMatch = skill?.name.toLowerCase().contains(query) ?? false;

      // Search in category name
      final category = skill != null ? _categories[skill.categoryId] : null;
      final categoryMatch =
          category?.name.toLowerCase().contains(query) ?? false;

      return titleMatch ||
          descriptionMatch ||
          subSkillMatch ||
          skillMatch ||
          categoryMatch;
    }).toList();
  }

  List<DailyTask> get _filteredDailyTasks {
    if (_searchController.text.isEmpty) return [];
    final query = _searchController.text.toLowerCase();
    return _allDailyTasks.where((task) {
      return task.taskName.toLowerCase().contains(query);
    }).toList();
  }

  List<Category> get _filteredCategories {
    if (_searchController.text.isEmpty) return [];
    final query = _searchController.text.toLowerCase();
    return _allCategories.where((category) {
      return category.name.toLowerCase().contains(query);
    }).toList();
  }

  List<Skill> get _filteredSkills {
    if (_searchController.text.isEmpty) return [];
    final query = _searchController.text.toLowerCase();
    return _allSkills.where((skill) {
      final nameMatch = skill.name.toLowerCase().contains(query);
      final categoryMatch =
          _categories[skill.categoryId]?.name.toLowerCase().contains(query) ??
          false;
      return nameMatch || categoryMatch;
    }).toList();
  }

  List<SubSkill> get _filteredSubSkills {
    if (_searchController.text.isEmpty) return [];
    final query = _searchController.text.toLowerCase();
    return _allSubSkills.where((subSkill) {
      final nameMatch = subSkill.name.toLowerCase().contains(query);
      final skill = _skills[subSkill.skillId];
      final skillMatch = skill?.name.toLowerCase().contains(query) ?? false;
      final categoryMatch = skill != null
          ? _categories[skill.categoryId]?.name.toLowerCase().contains(query) ??
                false
          : false;
      return nameMatch || skillMatch || categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasResults =
        _filteredGoals.isNotEmpty ||
        _filteredDailyTasks.isNotEmpty ||
        _filteredCategories.isNotEmpty ||
        _filteredSkills.isNotEmpty ||
        _filteredSubSkills.isNotEmpty;
    final hasQuery = _searchController.text.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            // Header with search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: Theme.of(context).textTheme.titleLarge,
                      decoration: InputDecoration(
                        hintText: 'Search all goals and tasks...',
                        hintStyle: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                                tooltip: 'Clear search',
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasQuery
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recent',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_recentGoals.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No recent activity',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start logging progress to see recent goals here',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.7),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._recentGoals.map((goal) {
                            final subSkill = _subSkills[goal.subSkillId];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.flag,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(
                                  goal.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (subSkill != null)
                                      Text(
                                        subSkill.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    if (goal.description != null)
                                      Text(
                                        goal.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push('/goals/${goal.id}');
                                },
                              ),
                            );
                          }),
                      ],
                    )
                  : !hasResults
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_filteredCategories.isNotEmpty) ...[
                          Text(
                            'Categories',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._filteredCategories.map((category) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.folder,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push(
                                    '/long-term-goals/${category.id}',
                                  );
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                        if (_filteredSkills.isNotEmpty) ...[
                          Text(
                            'Skills',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._filteredSkills.map((skill) {
                            final category = _categories[skill.categoryId];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.school,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                title: Text(
                                  skill.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: category != null
                                    ? Text(
                                        category.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      )
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  if (category != null) {
                                    Navigator.of(context).pop();
                                    context.push(
                                      '/long-term-goals/${category.id}/skills/${skill.id}',
                                    );
                                  }
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                        if (_filteredSubSkills.isNotEmpty) ...[
                          Text(
                            'Sub-Skills',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._filteredSubSkills.map((subSkill) {
                            final skill = _skills[subSkill.skillId];
                            final category = skill != null
                                ? _categories[skill.categoryId]
                                : null;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.auto_awesome,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                title: Text(
                                  subSkill.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: skill != null && category != null
                                    ? Text(
                                        '${skill.name} • ${category.name}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      )
                                    : skill != null
                                    ? Text(
                                        skill.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      )
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  if (skill != null && category != null) {
                                    Navigator.of(context).pop();
                                    context.push(
                                      '/long-term-goals/${category.id}/skills/${skill.id}/sub-skills/${subSkill.id}',
                                    );
                                  }
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                        if (_filteredGoals.isNotEmpty) ...[
                          Text(
                            'Long-Term Goals',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._filteredGoals.map((goal) {
                            final subSkill = _subSkills[goal.subSkillId];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.flag,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(
                                  goal.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (subSkill != null)
                                      Text(
                                        subSkill.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    if (goal.description != null)
                                      Text(
                                        goal.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push('/goals/${goal.id}');
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                        if (_filteredDailyTasks.isNotEmpty) ...[
                          Text(
                            'Daily Tasks',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._filteredDailyTasks.map((task) {
                            final shortTermGoal =
                                _shortTermGoals[task.shortTermGoalId];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.check_circle_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                title: Text(
                                  task.taskName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: shortTermGoal != null
                                    ? Text(
                                        'From: ${shortTermGoal.title}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      )
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  if (shortTermGoal != null) {
                                    context.push(
                                      '/short-term-goals/${shortTermGoal.id}',
                                    );
                                  }
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
