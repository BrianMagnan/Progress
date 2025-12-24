import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../services/supabase_database_service.dart';
import 'global_search_screen.dart';
import '../utils/helpers.dart';
import '../widgets/breadcrumb_nav.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService.instance;
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _db.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      // If there's an error, show it and set empty list
      debugPrint('Error loading categories: $e');
      setState(() {
        _categories = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Long Term Goal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Long term goal name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final now = DateTime.now();
      // Set order to the end of the list
      final maxOrder = _categories.isEmpty
          ? 0
          : _categories.map((c) => c.order).reduce((a, b) => a > b ? a : b);
      final category = Category(
        id: generateId(),
        name: result,
        order: maxOrder + 1,
        createdAt: now,
        updatedAt: now,
      );
      try {
        await _db.createCategory(category);
        // Small delay to ensure IndexedDB write completes before reloading
        await Future.delayed(const Duration(milliseconds: 100));
        _loadCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving long term goal: $e'),
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

    final item = _categories[oldIndex];
    setState(() {
      _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    // Update order values for all categories that changed
    final now = DateTime.now();
    final int startIndex = oldIndex < newIndex ? oldIndex : newIndex;
    final int endIndex = oldIndex < newIndex ? newIndex : oldIndex;

    for (int i = startIndex; i <= endIndex; i++) {
      final category = _categories[i];
      final updatedCategory = category.copyWith(order: i, updatedAt: now);
      await _db.updateCategory(updatedCategory);
    }
  }

  Future<void> _editCategory(Category category) async {
    final controller = TextEditingController(text: category.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Long Term Goal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Long term goal name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final now = DateTime.now();
      final updatedCategory = category.copyWith(name: result, updatedAt: now);
      try {
        await _db.updateCategory(updatedCategory);
        // Small delay to ensure IndexedDB write completes before reloading
        await Future.delayed(const Duration(milliseconds: 100));
        _loadCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating long term goal: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Long Term Goal'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This will also delete all associated skills, sub-skills, goals, and progress logs.',
        ),
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
      await _db.deleteCategory(category.id);
      _loadCategories();
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
        title: const Text('Long Term Goals'),
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
            onPressed: _addCategory,
            tooltip: 'Add long term goal',
          ),
        ],
      ),
      body: Column(
        children: [
          BreadcrumbNav(
            items: const [
              BreadcrumbItem(label: 'Home', route: '/'),
              BreadcrumbItem(label: 'Long Term Goals'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No long term goals yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first long term goal to get started',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
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
                final category = _categories[index];
                return Card(
                  key: ValueKey(category.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.folder,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () {
                            Future.delayed(
                              Duration.zero,
                              () => _editCategory(category),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () => _deleteCategory(category),
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/long-term-goals/${category.id}');
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


