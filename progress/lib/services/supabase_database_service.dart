import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/skill.dart';
import '../models/sub_skill.dart';
import '../models/goal.dart';
import '../models/short_term_goal.dart';
import '../models/daily_task.dart';
import '../models/progress_log.dart';
import '../config/supabase_config.dart';

class SupabaseDatabaseService {
  static final SupabaseDatabaseService instance =
      SupabaseDatabaseService._init();

  SupabaseDatabaseService._init();

  bool _initialized = false;
  late SupabaseClient _supabase;

  Future<void> init() async {
    if (_initialized) {
      developer.log('SupabaseDatabaseService: Already initialized');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _supabase = Supabase.instance.client;
      _initialized = true;
      developer.log('SupabaseDatabaseService: Initialized successfully');
    } catch (e, stackTrace) {
      developer.log(
        'SupabaseDatabaseService: Initialization failed: $e',
        name: 'ERROR',
      );
      developer.log(
        'SupabaseDatabaseService: Stack trace: $stackTrace',
        name: 'ERROR',
      );
      rethrow;
    }
  }

  SupabaseClient get client {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _supabase;
  }

  // Category CRUD
  Future<String> createCategory(Category category) async {
    try {
      await client.from('categories').insert(category.toMap());
      developer.log('createCategory: Saved category ${category.name}');
      return category.id;
    } catch (e, stackTrace) {
      developer.log('createCategory: Exception: $e', name: 'ERROR');
      developer.log('createCategory: Stack trace: $stackTrace', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<Category>> getAllCategories() async {
    try {
      final response = await client
          .from('categories')
          .select()
          .order('order', ascending: true);

      return (response as List)
          .map((map) => Category.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e) {
      developer.log('getAllCategories: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<Category?> getCategory(String id) async {
    try {
      final response = await client
          .from('categories')
          .select()
          .eq('id', id)
          .single();

      return Category.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      developer.log('getCategory: Error: $e', name: 'ERROR');
      return null;
    }
  }

  Future<int> updateCategory(Category category) async {
    try {
      await client
          .from('categories')
          .update(category.toMap())
          .eq('id', category.id);
      return 1;
    } catch (e) {
      developer.log('updateCategory: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<int> deleteCategory(String id) async {
    try {
      await client.from('categories').delete().eq('id', id);
      return 1;
    } catch (e) {
      developer.log('deleteCategory: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  // Skill CRUD
  Future<String> createSkill(Skill skill) async {
    try {
      await client.from('skills').insert(skill.toMap());
      developer.log('createSkill: Saved skill ${skill.name}');
      return skill.id;
    } catch (e, stackTrace) {
      developer.log('createSkill: Exception: $e', name: 'ERROR');
      developer.log('createSkill: Stack trace: $stackTrace', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<Skill>> getSkillsByCategory(String categoryId) async {
    try {
      final response = await client
          .from('skills')
          .select()
          .eq('category_id', categoryId)
          .order('order', ascending: true);

      return (response as List)
          .map((map) => Skill.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e) {
      developer.log('getSkillsByCategory: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<Skill?> getSkill(String id) async {
    try {
      final response = await client
          .from('skills')
          .select()
          .eq('id', id)
          .single();

      return Skill.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      developer.log('getSkill: Error: $e', name: 'ERROR');
      return null;
    }
  }

  Future<int> updateSkill(Skill skill) async {
    try {
      await client.from('skills').update(skill.toMap()).eq('id', skill.id);
      return 1;
    } catch (e) {
      developer.log('updateSkill: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<int> deleteSkill(String id) async {
    try {
      await client.from('skills').delete().eq('id', id);
      return 1;
    } catch (e) {
      developer.log('deleteSkill: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  // SubSkill CRUD
  Future<String> createSubSkill(SubSkill subSkill) async {
    try {
      final data = subSkill.toMap();
      // Remove order if column doesn't exist yet (temporary workaround)
      // Remove this try-catch once you've added the order column
      try {
        await client.from('sub_skills').insert(data);
      } catch (e) {
        // If error mentions "order" column, try without it
        if (e.toString().contains('order') || e.toString().contains('column')) {
          final dataWithoutOrder = Map<String, dynamic>.from(data);
          dataWithoutOrder.remove('order');
          await client.from('sub_skills').insert(dataWithoutOrder);
        } else {
          rethrow;
        }
      }
      return subSkill.id;
    } catch (e) {
      developer.log('createSubSkill: Exception: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<SubSkill>> getSubSkillsBySkill(String skillId) async {
    try {
      // Fetch all sub-skills for this skill
      final response = await client
          .from('sub_skills')
          .select()
          .eq('skill_id', skillId);
      
      final subSkills = (response as List)
          .map((map) => SubSkill.fromMap(Map<String, dynamic>.from(map)))
          .toList();
      
      // Sort by order column, then by created_at as tiebreaker
      // Using Dart-side sorting to avoid issues with reserved word "order" in Supabase queries
      subSkills.sort((a, b) {
        final orderComparison = a.order.compareTo(b.order);
        if (orderComparison != 0) {
          return orderComparison;
        }
        // If order is the same, sort by created_at
        return a.createdAt.compareTo(b.createdAt);
      });
      
      return subSkills;
    } catch (e) {
      developer.log('getSubSkillsBySkill: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<SubSkill?> getSubSkill(String id) async {
    try {
      final response = await client
          .from('sub_skills')
          .select()
          .eq('id', id)
          .single();

      return SubSkill.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      developer.log('getSubSkill: Error: $e', name: 'ERROR');
      return null;
    }
  }

  Future<int> updateSubSkill(SubSkill subSkill) async {
    try {
      await client
          .from('sub_skills')
          .update(subSkill.toMap())
          .eq('id', subSkill.id);
      return 1;
    } catch (e) {
      developer.log('updateSubSkill: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<int> deleteSubSkill(String id) async {
    try {
      await client.from('sub_skills').delete().eq('id', id);
      return 1;
    } catch (e) {
      developer.log('deleteSubSkill: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  // Goal CRUD
  Future<String> createGoal(Goal goal) async {
    try {
      final data = goal.toMap();
      // Remove order if column doesn't exist yet (temporary workaround)
      // Remove this try-catch once you've added the order column
      try {
        await client.from('goals').insert(data);
      } catch (e) {
        // If error mentions "order" column, try without it
        if (e.toString().contains('order') || e.toString().contains('column')) {
          final dataWithoutOrder = Map<String, dynamic>.from(data);
          dataWithoutOrder.remove('order');
          await client.from('goals').insert(dataWithoutOrder);
        } else {
          rethrow;
        }
      }
      return goal.id;
    } catch (e) {
      developer.log('createGoal: Exception: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<Goal>> getGoalsBySubSkill(String subSkillId) async {
    try {
      final response = await client
          .from('goals')
          .select()
          .eq('sub_skill_id', subSkillId);
      
      // Try to order by 'order', fallback to 'created_at' if column doesn't exist
      try {
        final orderedResponse = await client
            .from('goals')
            .select()
            .eq('sub_skill_id', subSkillId)
            .order('order', ascending: true);
        return (orderedResponse as List)
            .map((map) => Goal.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      } catch (e) {
        // If order column doesn't exist, sort by created_at
        final sortedResponse = (response as List)
            .map((map) => Goal.fromMap(Map<String, dynamic>.from(map)))
            .toList();
        sortedResponse.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sortedResponse;
      }
    } catch (e) {
      developer.log('getGoalsBySubSkill: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<List<Goal>> getAllGoals() async {
    try {
      // Fetch all goals without ordering
      final response = await client
          .from('goals')
          .select();
      
      final goals = (response as List)
          .map((map) => Goal.fromMap(Map<String, dynamic>.from(map)))
          .toList();
      
      // Sort by order column, then by created_at as tiebreaker
      // Using Dart-side sorting to avoid issues with reserved word "order" in Supabase queries
      goals.sort((a, b) {
        final orderComparison = a.order.compareTo(b.order);
        if (orderComparison != 0) {
          return orderComparison;
        }
        // If order is the same, sort by created_at (descending)
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return goals;
    } catch (e) {
      developer.log('getAllGoals: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<Goal?> getGoal(String id) async {
    try {
      final response = await client
          .from('goals')
          .select()
          .eq('id', id)
          .single();

      return Goal.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      developer.log('getGoal: Error: $e', name: 'ERROR');
      return null;
    }
  }

  Future<int> updateGoal(Goal goal) async {
    try {
      await client.from('goals').update(goal.toMap()).eq('id', goal.id);
      return 1;
    } catch (e) {
      developer.log('updateGoal: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<int> deleteGoal(String id) async {
    try {
      await client.from('goals').delete().eq('id', id);
      return 1;
    } catch (e) {
      developer.log('deleteGoal: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  // ProgressLog CRUD
  Future<String> createProgressLog(ProgressLog log) async {
    try {
      await client.from('progress_logs').insert(log.toMap());
      return log.id;
    } catch (e) {
      developer.log('createProgressLog: Exception: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<ProgressLog>> getProgressLogsByGoal(String goalId) async {
    try {
      final response = await client
          .from('progress_logs')
          .select()
          .eq('goal_id', goalId)
          .order('date', ascending: false);

      return (response as List).map((map) {
        // Convert date from ISO string if needed
        final data = Map<String, dynamic>.from(map);
        if (data['date'] is String) {
          data['date'] = data['date'];
        }
        return ProgressLog.fromMap(data);
      }).toList();
    } catch (e) {
      developer.log('getProgressLogsByGoal: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<ProgressLog?> getLatestProgressLog(String goalId) async {
    try {
      final response = await client
          .from('progress_logs')
          .select()
          .eq('goal_id', goalId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return ProgressLog.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      developer.log('getLatestProgressLog: Error: $e', name: 'ERROR');
      return null;
    }
  }

  Future<ProgressLog?> getProgressLog(String id) async {
    try {
      final response = await client
          .from('progress_logs')
          .select()
          .eq('id', id)
          .single();

      return ProgressLog.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      developer.log('getProgressLog: Error: $e', name: 'ERROR');
      return null;
    }
  }

  Future<int> updateProgressLog(ProgressLog log) async {
    try {
      await client.from('progress_logs').update(log.toMap()).eq('id', log.id);
      return 1;
    } catch (e) {
      developer.log('updateProgressLog: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<int> deleteProgressLog(String id) async {
    try {
      await client.from('progress_logs').delete().eq('id', id);
      return 1;
    } catch (e) {
      developer.log('deleteProgressLog: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  // Helper queries
  Future<int> getTotalProgressLogsCount(String goalId) async {
    try {
      final response = await client
          .from('progress_logs')
          .select('id')
          .eq('goal_id', goalId);

      return (response as List).length;
    } catch (e) {
      developer.log('getTotalProgressLogsCount: Error: $e', name: 'ERROR');
      return 0;
    }
  }

  Future<int> getTotalDurationMinutes(String goalId) async {
    try {
      final response = await client
          .from('progress_logs')
          .select('duration_minutes')
          .eq('goal_id', goalId);

      int total = 0;
      for (var log in (response as List)) {
        final map = Map<String, dynamic>.from(log);
        final minutes = map['duration_minutes'] as int?;
        if (minutes != null) {
          total += minutes;
        }
      }
      return total;
    } catch (e) {
      developer.log('getTotalDurationMinutes: Error: $e', name: 'ERROR');
      return 0;
    }
  }

  Future<List<ProgressLog>> getRecentActivity({int limit = 10}) async {
    try {
      final response = await client
          .from('progress_logs')
          .select()
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((map) => ProgressLog.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e) {
      developer.log('getRecentActivity: Error: $e', name: 'ERROR');
      return [];
    }
  }

  // Short Term Goal CRUD
  Future<String> createShortTermGoal(ShortTermGoal goal) async {
    try {
      final data = goal.toMap();
      // Remove order if column doesn't exist yet (temporary workaround)
      try {
        await client.from('short_term_goals').insert(data);
      } catch (e) {
        if (e.toString().contains('order') || e.toString().contains('column')) {
          final dataWithoutOrder = Map<String, dynamic>.from(data);
          dataWithoutOrder.remove('order');
          await client.from('short_term_goals').insert(dataWithoutOrder);
        } else {
          rethrow;
        }
      }
      return goal.id;
    } catch (e) {
      developer.log('createShortTermGoal: Exception: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<ShortTermGoal>> getAllShortTermGoals() async {
    try {
      final response = await client
          .from('short_term_goals')
          .select();
      
      // Try to order by 'order', fallback to 'created_at' if column doesn't exist
      try {
        final orderedResponse = await client
            .from('short_term_goals')
            .select()
            .order('order', ascending: true);
        return (orderedResponse as List)
            .map((map) => ShortTermGoal.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      } catch (e) {
        // If order column doesn't exist, sort by created_at
        final sortedResponse = (response as List)
            .map((map) => ShortTermGoal.fromMap(Map<String, dynamic>.from(map)))
            .toList();
        sortedResponse.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sortedResponse;
      }
    } catch (e) {
      developer.log('getAllShortTermGoals: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<ShortTermGoal?> getShortTermGoal(String id) async {
    try {
      final response = await client
          .from('short_term_goals')
          .select()
          .eq('id', id)
          .single();

      return ShortTermGoal.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      developer.log('getShortTermGoal: Error: $e', name: 'ERROR');
      return null;
    }
  }

  Future<int> updateShortTermGoal(ShortTermGoal goal) async {
    try {
      await client.from('short_term_goals').update(goal.toMap()).eq('id', goal.id);
      return 1;
    } catch (e) {
      developer.log('updateShortTermGoal: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<int> deleteShortTermGoal(String id) async {
    try {
      await client.from('short_term_goals').delete().eq('id', id);
      return 1;
    } catch (e) {
      developer.log('deleteShortTermGoal: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  // DailyTask CRUD
  Future<String> createDailyTask(DailyTask task) async {
    try {
      final data = task.toMap();
      try {
        await client.from('daily_tasks').insert(data);
      } catch (e) {
        if (e.toString().contains('order') || e.toString().contains('column')) {
          final dataWithoutOrder = Map<String, dynamic>.from(data);
          dataWithoutOrder.remove('order');
          await client.from('daily_tasks').insert(dataWithoutOrder);
        } else {
          rethrow;
        }
      }
      return task.id;
    } catch (e) {
      developer.log('createDailyTask: Exception: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<DailyTask>> getAllDailyTasks() async {
    try {
      final response = await client
          .from('daily_tasks')
          .select();
      
      // Try to order by 'order', fallback to 'created_at' if column doesn't exist
      try {
        final orderedResponse = await client
            .from('daily_tasks')
            .select()
            .order('order', ascending: true);
        return (orderedResponse as List)
            .map((map) => DailyTask.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      } catch (e) {
        // If order column doesn't exist, sort by created_at
        final sortedResponse = (response as List)
            .map((map) => DailyTask.fromMap(Map<String, dynamic>.from(map)))
            .toList();
        sortedResponse.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return sortedResponse;
      }
    } catch (e) {
      developer.log('getAllDailyTasks: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<List<DailyTask>> getDailyTasksByGoal(String shortTermGoalId) async {
    try {
      final response = await client
          .from('daily_tasks')
          .select()
          .eq('short_term_goal_id', shortTermGoalId);
      
      // Try to order by 'order', fallback to 'created_at' if column doesn't exist
      try {
        final orderedResponse = await client
            .from('daily_tasks')
            .select()
            .eq('short_term_goal_id', shortTermGoalId)
            .order('order', ascending: true);
        return (orderedResponse as List)
            .map((map) => DailyTask.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      } catch (e) {
        // If order column doesn't exist, sort by created_at
        final sortedResponse = (response as List)
            .map((map) => DailyTask.fromMap(Map<String, dynamic>.from(map)))
            .toList();
        sortedResponse.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return sortedResponse;
      }
    } catch (e) {
      developer.log('getDailyTasksByGoal: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<int> updateDailyTask(DailyTask task) async {
    try {
      await client.from('daily_tasks').update(task.toMap()).eq('id', task.id);
      return 1;
    } catch (e) {
      developer.log('updateDailyTask: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<int> deleteDailyTask(String id) async {
    try {
      await client.from('daily_tasks').delete().eq('id', id);
      return 1;
    } catch (e) {
      developer.log('deleteDailyTask: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  // DailyTaskCompletion CRUD
  Future<String> createDailyTaskCompletion(DailyTaskCompletion completion) async {
    try {
      await client.from('daily_task_completions').insert(completion.toMap());
      return completion.id;
    } catch (e) {
      developer.log('createDailyTaskCompletion: Exception: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<List<DailyTaskCompletion>> getCompletionsByTask(String dailyTaskId) async {
    try {
      final response = await client
          .from('daily_task_completions')
          .select()
          .eq('daily_task_id', dailyTaskId)
          .order('date', ascending: false);

      return (response as List)
          .map((map) => DailyTaskCompletion.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e) {
      developer.log('getCompletionsByTask: Error: $e', name: 'ERROR');
      return [];
    }
  }

  Future<DailyTaskCompletion?> getCompletionForDate(String dailyTaskId, DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await client
          .from('daily_task_completions')
          .select()
          .eq('daily_task_id', dailyTaskId)
          .gte('date', '${dateStr}T00:00:00')
          .lte('date', '${dateStr}T23:59:59')
          .maybeSingle();

      if (response == null) return null;
      return DailyTaskCompletion.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      developer.log('getCompletionForDate: Error: $e', name: 'ERROR');
      return null;
    }
  }

  Future<int> updateDailyTaskCompletion(DailyTaskCompletion completion) async {
    try {
      await client.from('daily_task_completions').update(completion.toMap()).eq('id', completion.id);
      return 1;
    } catch (e) {
      developer.log('updateDailyTaskCompletion: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<int> deleteDailyTaskCompletion(String id) async {
    try {
      await client.from('daily_task_completions').delete().eq('id', id);
      return 1;
    } catch (e) {
      developer.log('deleteDailyTaskCompletion: Error: $e', name: 'ERROR');
      rethrow;
    }
  }

  Future<void> closeAll() async {
    // Supabase doesn't need explicit closing
    developer.log('SupabaseDatabaseService: closeAll called (no-op)');
  }
}
