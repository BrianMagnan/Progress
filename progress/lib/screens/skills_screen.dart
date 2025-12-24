import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/skill.dart';
import '../services/supabase_database_service.dart';
import 'global_search_screen.dart';
import '../utils/helpers.dart';
import '../widgets/breadcrumb_nav.dart';

class SkillsScreen extends StatefulWidget {
  final Category category;

  const SkillsScreen({super.key, required this.category});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService.instance;
  List<Skill> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() => _isLoading = true);
    final skills = await _db.getSkillsByCategory(widget.category.id);
    setState(() {
      _skills = skills;
      _isLoading = false;
    });
  }

  Future<void> _addSkill() async {
    final nameController = TextEditingController();
    final levelController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        void submitForm() {
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
        }

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('New Skill'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Skill name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => submitForm(),
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
                  onSubmitted: (_) => submitForm(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(onPressed: submitForm, child: const Text('Create')),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final now = DateTime.now();
      // Set order to the end of the list
      final maxOrder = _skills.isEmpty
          ? 0
          : _skills.map((s) => s.order).reduce((a, b) => a > b ? a : b);
      final skill = Skill(
        id: generateId(),
        categoryId: widget.category.id,
        name: result['name'],
        skillLevel: result['level'],
        order: maxOrder + 1,
        createdAt: now,
        updatedAt: now,
      );
      try {
        await _db.createSkill(skill);
        // Small delay to ensure IndexedDB write completes before reloading
        await Future.delayed(const Duration(milliseconds: 100));
        _loadSkills();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving skill: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editSkill(Skill skill) async {
    final nameController = TextEditingController(text: skill.name);
    final levelController = TextEditingController(
      text: skill.skillLevel?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Skill name',
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
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      final updatedSkill = skill.copyWith(
        name: result['name'],
        skillLevel: result['level'],
        updatedAt: now,
      );
      try {
        await _db.updateSkill(updatedSkill);
        // Small delay to ensure IndexedDB write completes before reloading
        await Future.delayed(const Duration(milliseconds: 100));
        _loadSkills();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating skill: $e'),
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

    final item = _skills[oldIndex];
    setState(() {
      _skills.removeAt(oldIndex);
      _skills.insert(newIndex, item);
    });

    // Update order values for all skills that changed
    final now = DateTime.now();
    final int startIndex = oldIndex < newIndex ? oldIndex : newIndex;
    final int endIndex = oldIndex < newIndex ? newIndex : oldIndex;

    for (int i = startIndex; i <= endIndex; i++) {
      final skill = _skills[i];
      final updatedSkill = skill.copyWith(order: i, updatedAt: now);
      await _db.updateSkill(updatedSkill);
    }
  }


  Future<void> _deleteSkill(Skill skill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Skill'),
        content: Text('Are you sure you want to delete "${skill.name}"?'),
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
        await _db.deleteSkill(skill.id);
        _loadSkills();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting skill: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
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
            onPressed: _addSkill,
            tooltip: 'Add skill',
          ),
        ],
      ),
      body: Column(
        children: [
          BreadcrumbNav(
            items: [
              const BreadcrumbItem(label: 'Home', route: '/'),
              const BreadcrumbItem(label: 'Long Term Goals', route: '/long-term-goals'),
              BreadcrumbItem(label: widget.category.name),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _skills.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No skills yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first skill in ${widget.category.name}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _skills.length,
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
              itemBuilder: (BuildContext context, int index) {
                final skill = _skills[index];
                return Card(
                  key: ValueKey(skill.id),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.psychology,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      skill.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: skill.skillLevel != null
                        ? Text('Level: ${skill.skillLevel}/10')
                        : null,
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () {
                            Future.delayed(
                              Duration.zero,
                              () => _editSkill(skill),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () {
                            Future.delayed(
                              Duration.zero,
                              () => _deleteSkill(skill),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/long-term-goals/${widget.category.id}/skills/${skill.id}').then((_) => _loadSkills());
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
