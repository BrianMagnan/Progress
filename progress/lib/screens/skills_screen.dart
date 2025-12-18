import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/skill.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';
import 'sub_skills_screen.dart';

class SkillsScreen extends StatefulWidget {
  final Category category;

  const SkillsScreen({super.key, required this.category});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final DatabaseService _db = DatabaseService.instance;
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
      builder: (context) => StatefulBuilder(
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
      ),
    );

    if (result != null) {
      final now = DateTime.now();
      final skill = Skill(
        id: generateId(),
        categoryId: widget.category.id,
        name: result['name'],
        skillLevel: result['level'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: _isLoading
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _skills.length,
              itemBuilder: (context, index) {
                final skill = _skills[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
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
                    title: Text(
                      skill.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: skill.skillLevel != null
                        ? Text('Level: ${skill.skillLevel}/10')
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubSkillsScreen(skill: skill),
                        ),
                      ).then((_) => _loadSkills());
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSkill,
        icon: const Icon(Icons.add),
        label: const Text('New Skill'),
      ),
    );
  }
}
