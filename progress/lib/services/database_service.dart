import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/skill.dart';
import '../models/sub_skill.dart';
import '../models/goal.dart';
import '../models/progress_log.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();

  static const String _categoriesBox = 'categories';
  static const String _skillsBox = 'skills';
  static const String _subSkillsBox = 'sub_skills';
  static const String _goalsBox = 'goals';
  static const String _progressLogsBox = 'progress_logs';

  DatabaseService._init();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      developer.log('DatabaseService: Already initialized, skipping');
      return;
    }

    developer.log('DatabaseService: Starting initialization...');

    // On web, Hive uses IndexedDB. The database name is based on the origin.
    // If the port changes, it's a different origin and different database!
    await Hive.initFlutter();
    developer.log('DatabaseService: Hive.initFlutter() completed');

    // On web, we need to close and reopen boxes to ensure fresh data from IndexedDB
    // This is necessary because Hive on web may cache data in memory
    if (Hive.isBoxOpen(_categoriesBox)) {
      final box = Hive.box(_categoriesBox);
      await box.flush(); // Save any pending writes
      await box.close();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    final categoriesBox = await Hive.openBox(_categoriesBox);
    // Wait for IndexedDB to load - openBox() returns immediately but data loads asynchronously
    await Future.delayed(const Duration(milliseconds: 500));
    categoriesBox.keys.toList(); // Force a read to trigger IndexedDB load

    if (Hive.isBoxOpen(_skillsBox)) {
      final box = Hive.box(_skillsBox);
      await box.flush();
      await box.close();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    final skillsBox = await Hive.openBox(_skillsBox);
    await Future.delayed(const Duration(milliseconds: 500));
    skillsBox.keys.toList(); // Force a read to trigger IndexedDB load

    if (Hive.isBoxOpen(_subSkillsBox)) {
      final box = Hive.box(_subSkillsBox);
      await box.flush();
      await box.close();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    await Hive.openBox(_subSkillsBox);

    if (Hive.isBoxOpen(_goalsBox)) {
      final box = Hive.box(_goalsBox);
      await box.flush();
      await box.close();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    await Hive.openBox(_goalsBox);

    if (Hive.isBoxOpen(_progressLogsBox)) {
      final box = Hive.box(_progressLogsBox);
      await box.flush();
      await box.close();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    await Hive.openBox(_progressLogsBox);

    // Additional wait for IndexedDB to fully load all data
    await Future.delayed(const Duration(milliseconds: 500));

    // Verify boxes are open
    if (!Hive.isBoxOpen(_categoriesBox) ||
        !Hive.isBoxOpen(_skillsBox) ||
        !Hive.isBoxOpen(_subSkillsBox) ||
        !Hive.isBoxOpen(_goalsBox) ||
        !Hive.isBoxOpen(_progressLogsBox)) {
      throw Exception('Failed to open Hive boxes');
    }

    developer.log('DatabaseService: All boxes initialized and open');
    _initialized = true;
    developer.log('DatabaseService: Initialization complete');
  }

  /// Close all boxes to ensure data is committed to IndexedDB
  /// Call this before app shutdown to ensure data persists
  Future<void> closeAll() async {
    try {
      if (Hive.isBoxOpen(_categoriesBox)) {
        await Hive.box(_categoriesBox).flush();
        await Hive.box(_categoriesBox).close();
      }
      if (Hive.isBoxOpen(_skillsBox)) {
        await Hive.box(_skillsBox).flush();
        await Hive.box(_skillsBox).close();
      }
      if (Hive.isBoxOpen(_subSkillsBox)) {
        await Hive.box(_subSkillsBox).flush();
        await Hive.box(_subSkillsBox).close();
      }
      if (Hive.isBoxOpen(_goalsBox)) {
        await Hive.box(_goalsBox).flush();
        await Hive.box(_goalsBox).close();
      }
      if (Hive.isBoxOpen(_progressLogsBox)) {
        await Hive.box(_progressLogsBox).flush();
        await Hive.box(_progressLogsBox).close();
      }
      developer.log('DatabaseService: All boxes closed');
    } catch (e) {
      developer.log('DatabaseService: Error closing boxes: $e', name: 'ERROR');
    }
  }

  Box get _categories {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return Hive.box(_categoriesBox);
  }

  Box get _skills {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return Hive.box(_skillsBox);
  }

  Box get _subSkills {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return Hive.box(_subSkillsBox);
  }

  Box get _goals {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return Hive.box(_goalsBox);
  }

  Box get _progressLogs {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return Hive.box(_progressLogsBox);
  }

  // Category CRUD
  Future<String> createCategory(Category category) async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen(_categoriesBox)) {
        await Hive.openBox(_categoriesBox);
      }

      final box = Hive.box(_categoriesBox);
      await box.put(category.id, category.toMap());
      await box.flush();
      await Future.delayed(const Duration(milliseconds: 200));
      await box.flush();

      developer.log('createCategory: Saved category ${category.name}');
      return category.id;
    } catch (e, stackTrace) {
      developer.log('createCategory: Exception occurred: $e', name: 'ERROR');
      developer.log('createCategory: Stack trace: $stackTrace', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<Category>> getAllCategories() async {
    // Ensure box is open (openBox() waits for it to be ready)
    if (!Hive.isBoxOpen(_categoriesBox)) {
      await Hive.openBox(_categoriesBox);
      // Wait a bit for IndexedDB to load on web
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Get all keys first to verify data exists
    final keys = _categories.keys.toList();
    developer.log('getAllCategories: Found ${keys.length} keys in box');

    // If empty, try one more time after a delay (for web IndexedDB async loading)
    if (keys.isEmpty) {
      developer.log(
        'getAllCategories: Box appears empty, waiting and retrying...',
      );
      await Future.delayed(const Duration(milliseconds: 200));
      final retryKeys = _categories.keys.toList();
      developer.log(
        'getAllCategories: After retry, found ${retryKeys.length} keys',
      );
      if (retryKeys.isEmpty) {
        developer.log('getAllCategories: Box is empty - no categories found');
        return [];
      }
      // Use retryKeys if we found some
      final categories = <Category>[];
      for (final key in retryKeys) {
        try {
          final map = _categories.get(key);
          if (map != null) {
            final categoryMap = Map<String, dynamic>.from(map as Map);
            if (!categoryMap.containsKey('order')) {
              categoryMap['order'] = 0;
            }
            categories.add(Category.fromMap(categoryMap));
            developer.log(
              'getAllCategories: Loaded category: ${categoryMap['name']}',
            );
          }
        } catch (e) {
          developer.log('getAllCategories: Error loading key $key: $e');
          continue;
        }
      }
      categories.sort((a, b) => a.order.compareTo(b.order));
      developer.log(
        'getAllCategories: Returning ${categories.length} categories',
      );
      return categories;
    }

    // Read each category by key to ensure we get the data
    final categories = <Category>[];
    for (final key in keys) {
      try {
        final map = _categories.get(key);
        if (map != null) {
          final categoryMap = Map<String, dynamic>.from(map as Map);
          // Ensure order field exists for backward compatibility
          if (!categoryMap.containsKey('order')) {
            categoryMap['order'] = 0;
          }
          categories.add(Category.fromMap(categoryMap));
          developer.log(
            'getAllCategories: Loaded category: ${categoryMap['name']}',
          );
        } else {
          developer.log('getAllCategories: Key $key returned null');
        }
      } catch (e) {
        developer.log('getAllCategories: Error loading key $key: $e');
        // Skip invalid entries
        continue;
      }
    }

    categories.sort((a, b) => a.order.compareTo(b.order));
    developer.log(
      'getAllCategories: Returning ${categories.length} categories',
    );
    return categories;
  }

  Future<Category?> getCategory(String id) async {
    final map = _categories.get(id);
    if (map == null) return null;
    return Category.fromMap(Map<String, dynamic>.from(map as Map));
  }

  Future<int> updateCategory(Category category) async {
    await _categories.put(category.id, category.toMap());
    await _categories.flush(); // Ensure data is written to disk
    return 1;
  }

  Future<int> deleteCategory(String id) async {
    await _categories.delete(id);
    await _categories.flush();
    return 1;
  }

  // Skill CRUD
  Future<String> createSkill(Skill skill) async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen(_skillsBox)) {
        await Hive.openBox(_skillsBox);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final box = Hive.box(_skillsBox);
      await box.put(skill.id, skill.toMap());
      await box.flush();
      await Future.delayed(const Duration(milliseconds: 200));
      await box.flush();

      developer.log('createSkill: Saved skill ${skill.name}');
      return skill.id;
    } catch (e, stackTrace) {
      developer.log('createSkill: Exception occurred: $e', name: 'ERROR');
      developer.log('createSkill: Stack trace: $stackTrace', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<Skill>> getSkillsByCategory(String categoryId) async {
    // Ensure box is open
    if (!Hive.isBoxOpen(_skillsBox)) {
      await Hive.openBox(_skillsBox);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final keys = _skills.keys.toList();

    // If empty, try one more time after a delay (for web IndexedDB async loading)
    if (keys.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      final retryKeys = _skills.keys.toList();
      if (retryKeys.isEmpty) return [];

      final skills = <Skill>[];
      for (final key in retryKeys) {
        try {
          final map = _skills.get(key);
          if (map != null) {
            final skill = Skill.fromMap(Map<String, dynamic>.from(map as Map));
            if (skill.categoryId == categoryId) {
              skills.add(skill);
            }
          }
        } catch (e) {
          continue;
        }
      }
      skills.sort((a, b) => a.name.compareTo(b.name));
      return skills;
    }

    final skills = <Skill>[];
    for (final key in keys) {
      try {
        final map = _skills.get(key);
        if (map != null) {
          final skill = Skill.fromMap(Map<String, dynamic>.from(map as Map));
          if (skill.categoryId == categoryId) {
            skills.add(skill);
          }
        }
      } catch (e) {
        continue;
      }
    }

    skills.sort((a, b) => a.name.compareTo(b.name));
    return skills;
  }

  Future<Skill?> getSkill(String id) async {
    final map = _skills.get(id);
    if (map == null) return null;
    return Skill.fromMap(Map<String, dynamic>.from(map as Map));
  }

  Future<int> updateSkill(Skill skill) async {
    await _skills.put(skill.id, skill.toMap());
    await _skills.flush();
    return 1;
  }

  Future<int> deleteSkill(String id) async {
    await _skills.delete(id);
    await _skills.flush();
    return 1;
  }

  // SubSkill CRUD
  Future<String> createSubSkill(SubSkill subSkill) async {
    try {
      if (!Hive.isBoxOpen(_subSkillsBox)) {
        await Hive.openBox(_subSkillsBox);
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await _subSkills.put(subSkill.id, subSkill.toMap());
      await _subSkills.flush();
      await Future.delayed(const Duration(milliseconds: 200));
      await _subSkills.flush();
      return subSkill.id;
    } catch (e) {
      developer.log('createSubSkill: Exception: $e');
      rethrow;
    }
  }

  Future<List<SubSkill>> getSubSkillsBySkill(String skillId) async {
    if (!Hive.isBoxOpen(_subSkillsBox)) {
      await Hive.openBox(_subSkillsBox);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final keys = _subSkills.keys.toList();
    if (keys.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      final retryKeys = _subSkills.keys.toList();
      if (retryKeys.isEmpty) return [];

      final subSkills = <SubSkill>[];
      for (final key in retryKeys) {
        try {
          final map = _subSkills.get(key);
          if (map != null) {
            final subSkill = SubSkill.fromMap(
              Map<String, dynamic>.from(map as Map),
            );
            if (subSkill.skillId == skillId) {
              subSkills.add(subSkill);
            }
          }
        } catch (e) {
          continue;
        }
      }
      subSkills.sort((a, b) => a.name.compareTo(b.name));
      return subSkills;
    }

    final subSkills = <SubSkill>[];
    for (final key in keys) {
      try {
        final map = _subSkills.get(key);
        if (map != null) {
          final subSkill = SubSkill.fromMap(
            Map<String, dynamic>.from(map as Map),
          );
          if (subSkill.skillId == skillId) {
            subSkills.add(subSkill);
          }
        }
      } catch (e) {
        continue;
      }
    }
    subSkills.sort((a, b) => a.name.compareTo(b.name));
    return subSkills;
  }

  Future<SubSkill?> getSubSkill(String id) async {
    final map = _subSkills.get(id);
    if (map == null) return null;
    return SubSkill.fromMap(Map<String, dynamic>.from(map as Map));
  }

  Future<int> updateSubSkill(SubSkill subSkill) async {
    await _subSkills.put(subSkill.id, subSkill.toMap());
    await _subSkills.flush();
    return 1;
  }

  Future<int> deleteSubSkill(String id) async {
    await _subSkills.delete(id);
    await _subSkills.flush();
    return 1;
  }

  // Goal CRUD
  Future<String> createGoal(Goal goal) async {
    try {
      if (!Hive.isBoxOpen(_goalsBox)) {
        await Hive.openBox(_goalsBox);
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await _goals.put(goal.id, goal.toMap());
      await _goals.flush();
      await Future.delayed(const Duration(milliseconds: 200));
      await _goals.flush();
      return goal.id;
    } catch (e) {
      developer.log('createGoal: Exception: $e');
      rethrow;
    }
  }

  Future<List<Goal>> getGoalsBySubSkill(String subSkillId) async {
    if (!Hive.isBoxOpen(_goalsBox)) {
      await Hive.openBox(_goalsBox);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final keys = _goals.keys.toList();
    if (keys.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      final retryKeys = _goals.keys.toList();
      if (retryKeys.isEmpty) return [];

      final goals = <Goal>[];
      for (final key in retryKeys) {
        try {
          final map = _goals.get(key);
          if (map != null) {
            final goal = Goal.fromMap(Map<String, dynamic>.from(map as Map));
            if (goal.subSkillId == subSkillId) {
              goals.add(goal);
            }
          }
        } catch (e) {
          continue;
        }
      }
      goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return goals;
    }

    final goals = <Goal>[];
    for (final key in keys) {
      try {
        final map = _goals.get(key);
        if (map != null) {
          final goal = Goal.fromMap(Map<String, dynamic>.from(map as Map));
          if (goal.subSkillId == subSkillId) {
            goals.add(goal);
          }
        }
      } catch (e) {
        continue;
      }
    }
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  Future<Goal?> getGoal(String id) async {
    final map = _goals.get(id);
    if (map == null) return null;
    return Goal.fromMap(Map<String, dynamic>.from(map as Map));
  }

  Future<int> updateGoal(Goal goal) async {
    await _goals.put(goal.id, goal.toMap());
    await _goals.flush();
    return 1;
  }

  Future<int> deleteGoal(String id) async {
    await _goals.delete(id);
    await _goals.flush();
    return 1;
  }

  // ProgressLog CRUD
  Future<String> createProgressLog(ProgressLog log) async {
    try {
      if (!Hive.isBoxOpen(_progressLogsBox)) {
        await Hive.openBox(_progressLogsBox);
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await _progressLogs.put(log.id, log.toMap());
      await _progressLogs.flush();
      await Future.delayed(const Duration(milliseconds: 200));
      await _progressLogs.flush();
      return log.id;
    } catch (e) {
      developer.log('createProgressLog: Exception: $e');
      rethrow;
    }
  }

  Future<List<ProgressLog>> getProgressLogsByGoal(String goalId) async {
    if (!Hive.isBoxOpen(_progressLogsBox)) {
      await Hive.openBox(_progressLogsBox);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final keys = _progressLogs.keys.toList();
    if (keys.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      final retryKeys = _progressLogs.keys.toList();
      if (retryKeys.isEmpty) return [];

      final logs = <ProgressLog>[];
      for (final key in retryKeys) {
        try {
          final map = _progressLogs.get(key);
          if (map != null) {
            final log = ProgressLog.fromMap(
              Map<String, dynamic>.from(map as Map),
            );
            if (log.goalId == goalId) {
              logs.add(log);
            }
          }
        } catch (e) {
          continue;
        }
      }
      logs.sort((a, b) => b.date.compareTo(a.date));
      return logs;
    }

    final logs = <ProgressLog>[];
    for (final key in keys) {
      try {
        final map = _progressLogs.get(key);
        if (map != null) {
          final log = ProgressLog.fromMap(
            Map<String, dynamic>.from(map as Map),
          );
          if (log.goalId == goalId) {
            logs.add(log);
          }
        }
      } catch (e) {
        continue;
      }
    }
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  Future<ProgressLog?> getLatestProgressLog(String goalId) async {
    final logs = await getProgressLogsByGoal(goalId);
    return logs.isEmpty ? null : logs.first;
  }

  Future<ProgressLog?> getProgressLog(String id) async {
    final map = _progressLogs.get(id);
    if (map == null) return null;
    return ProgressLog.fromMap(Map<String, dynamic>.from(map as Map));
  }

  Future<int> updateProgressLog(ProgressLog log) async {
    await _progressLogs.put(log.id, log.toMap());
    await _progressLogs.flush();
    return 1;
  }

  Future<int> deleteProgressLog(String id) async {
    await _progressLogs.delete(id);
    await _progressLogs.flush();
    return 1;
  }

  // Helper queries for statistics
  Future<int> getTotalProgressLogsCount(String goalId) async {
    final logs = await getProgressLogsByGoal(goalId);
    return logs.length;
  }

  Future<int> getTotalDurationMinutes(String goalId) async {
    final logs = await getProgressLogsByGoal(goalId);
    int total = 0;
    for (final log in logs) {
      if (log.durationMinutes != null) {
        total += log.durationMinutes!;
      }
    }
    return total;
  }

  // Get recent activity across all goals
  Future<List<ProgressLog>> getRecentActivity({int limit = 10}) async {
    final maps = _progressLogs.values.cast<Map>().toList();
    final logs = maps
        .map((map) => ProgressLog.fromMap(Map<String, dynamic>.from(map)))
        .toList();
    // Sort by date descending
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs.take(limit).toList();
  }

  Future<void> close() async {
    await Hive.close();
  }
}
