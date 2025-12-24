import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/skill.dart';
import '../models/sub_skill.dart';
import '../models/category.dart';
import '../services/supabase_database_service.dart';
import 'global_search_screen.dart';
import '../utils/helpers.dart';
import '../widgets/breadcrumb_nav.dart';

class SubSkillsScreen extends StatefulWidget {
  final Skill skill;

  const SubSkillsScreen({super.key, required this.skill});

  @override
  State<SubSkillsScreen> createState() => _SubSkillsScreenState();
}

class _SubSkillsScreenState extends State<SubSkillsScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService.instance;
  List<SubSkill> _subSkills = [];
  Category? _category;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final subSkills = await _db.getSubSkillsBySkill(widget.skill.id);
    final category = await _db.getCategory(widget.skill.categoryId);
    setState(() {
      _subSkills = subSkills;
      _category = category;
      _isLoading = false;
    });
  }

  Future<void> _loadSubSkills() async {
    final subSkills = await _db.getSubSkillsBySkill(widget.skill.id);
    setState(() {
      _subSkills = subSkills;
    });
  }


  Future<void> _addSubSkill() async {
    final nameController = TextEditingController();
    final levelController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Sub-Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Sub-skill name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: levelController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Skill level (1-10, optional)',
                border: OutlineInputBorder(),
                helperText: 'Your current confidence level',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final level = levelController.text.trim().isEmpty
                    ? null
                    : int.tryParse(levelController.text.trim());
                if (level != null && (level < 1 || level > 10)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Skill level must be between 1 and 10'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'level': level,
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      // Set order to the end of the list
      final maxOrder = _subSkills.isEmpty
          ? -1
          : _subSkills.map((s) => s.order).reduce((a, b) => a > b ? a : b);
      final subSkill = SubSkill(
        id: generateId(),
        skillId: widget.skill.id,
        name: result['name'],
        skillLevel: result['level'],
        order: maxOrder + 1,
        createdAt: now,
        updatedAt: now,
      );
      try {
        await _db.createSubSkill(subSkill);
        _loadSubSkills();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving sub-skill: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editSubSkill(SubSkill subSkill) async {
    final nameController = TextEditingController(text: subSkill.name);
    final levelController = TextEditingController(
      text: subSkill.skillLevel?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Sub-Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Sub-skill name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: levelController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Skill level (1-10, optional)',
                border: OutlineInputBorder(),
                helperText: 'Your current confidence level',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final level = levelController.text.trim().isEmpty
                    ? null
                    : int.tryParse(levelController.text.trim());
                if (level != null && (level < 1 || level > 10)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Skill level must be between 1 and 10'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'level': level,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      final updatedSubSkill = subSkill.copyWith(
        name: result['name'],
        skillLevel: result['level'],
        updatedAt: now,
      );
      try {
        await _db.updateSubSkill(updatedSubSkill);
        _loadSubSkills();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating sub-skill: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSubSkill(SubSkill subSkill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sub-Skill'),
        content: Text('Are you sure you want to delete "${subSkill.name}"? This will also delete all associated goals.'),
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
        await _db.deleteSubSkill(subSkill.id);
        _loadSubSkills();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting sub-skill: $e'),
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

    final item = _subSkills[oldIndex];
    setState(() {
      _subSkills.removeAt(oldIndex);
      _subSkills.insert(newIndex, item);
    });

    // Update order values for all sub-skills that changed
    final now = DateTime.now();
    final int startIndex = oldIndex < newIndex ? oldIndex : newIndex;
    final int endIndex = oldIndex < newIndex ? newIndex : oldIndex;

    for (int i = startIndex; i <= endIndex; i++) {
      final subSkill = _subSkills[i];
      final updatedSubSkill = subSkill.copyWith(order: i, updatedAt: now);
      await _db.updateSubSkill(updatedSubSkill);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill.name),
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
            onPressed: _addSubSkill,
            tooltip: 'Add sub-skill',
          ),
        ],
      ),
      body: Column(
        children: [
          BreadcrumbNav(
            items: _category != null
                ? [
                    const BreadcrumbItem(label: 'Home', route: '/'),
                    const BreadcrumbItem(label: 'Long Term Goals', route: '/long-term-goals'),
                    BreadcrumbItem(
                      label: _category!.name,
                      route: '/long-term-goals/${_category!.id}',
                    ),
                    BreadcrumbItem(
                      label: widget.skill.name,
                      route: '/long-term-goals/${widget.skill.categoryId}/skills/${widget.skill.id}',
                    ),
                  ]
                : [
                    const BreadcrumbItem(label: 'Home', route: '/'),
                    const BreadcrumbItem(label: 'Long Term Goals', route: '/long-term-goals'),
                    BreadcrumbItem(label: widget.skill.name),
                  ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subSkills.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sub-skills yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add sub-skills to break down ${widget.skill.name}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : _subSkills.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sub-skills yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first sub-skill for ${widget.skill.name}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _subSkills.length,
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
                final subSkill = _subSkills[index];
                    return Card(
                      key: ValueKey(subSkill.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          child: Icon(
                            Icons.auto_awesome,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                        ),
                        title: Text(
                          subSkill.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: subSkill.skillLevel != null
                            ? Text('Level: ${subSkill.skillLevel}/10')
                            : null,
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () {
                                Future.delayed(
                                  Duration.zero,
                                  () => _editSubSkill(subSkill),
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () {
                                Future.delayed(
                                  Duration.zero,
                                  () => _deleteSubSkill(subSkill),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          context.push('/long-term-goals/${widget.skill.categoryId}/skills/${widget.skill.id}/sub-skills/${subSkill.id}');
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
