import 'package:flutter/material.dart';
import '../models/skill.dart';
import '../models/sub_skill.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';
import 'goals_screen.dart';

class SubSkillsScreen extends StatefulWidget {
  final Skill skill;

  const SubSkillsScreen({super.key, required this.skill});

  @override
  State<SubSkillsScreen> createState() => _SubSkillsScreenState();
}

class _SubSkillsScreenState extends State<SubSkillsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<SubSkill> _subSkills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubSkills();
  }

  Future<void> _loadSubSkills() async {
    setState(() => _isLoading = true);
    final subSkills = await _db.getSubSkillsBySkill(widget.skill.id);
    setState(() {
      _subSkills = subSkills;
      _isLoading = false;
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
                    const SnackBar(content: Text('Skill level must be between 1 and 10')),
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
      final subSkill = SubSkill(
        id: generateId(),
        skillId: widget.skill.id,
        name: result['name'],
        skillLevel: result['level'],
        createdAt: now,
        updatedAt: now,
      );
      await _db.createSubSkill(subSkill);
      _loadSubSkills();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill.name),
      ),
      body: _isLoading
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subSkills.length,
                  itemBuilder: (context, index) {
                    final subSkill = _subSkills[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                          child: Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                        ),
                        title: Text(
                          subSkill.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: subSkill.skillLevel != null
                            ? Text('Level: ${subSkill.skillLevel}/10')
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GoalsScreen(subSkill: subSkill),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubSkill,
        icon: const Icon(Icons.add),
        label: const Text('New Sub-Skill'),
      ),
    );
  }
}

