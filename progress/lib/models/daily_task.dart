class DailyTask {
  final String id;
  final String shortTermGoalId;
  final String taskName;
  final int? dayOfWeek; // 0 = Monday, 1 = Tuesday, ..., 6 = Sunday, null = specific date
  final DateTime? specificDate; // If dayOfWeek is null, use this specific date
  final bool isRecurring; // If true, repeats weekly on dayOfWeek
  final bool isDaily; // If true, occurs every day
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyTask({
    required this.id,
    required this.shortTermGoalId,
    required this.taskName,
    this.dayOfWeek,
    this.specificDate,
    this.isRecurring = false,
    this.isDaily = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'short_term_goal_id': shortTermGoalId,
      'task_name': taskName,
      'day_of_week': dayOfWeek,
      'specific_date': specificDate?.toIso8601String(),
      'is_recurring': isRecurring,
      'is_daily': isDaily,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] as String,
      shortTermGoalId: map['short_term_goal_id'] as String,
      taskName: map['task_name'] as String,
      dayOfWeek: map['day_of_week'] as int?,
      specificDate: map['specific_date'] != null
          ? DateTime.parse(map['specific_date'] as String)
          : null,
      isRecurring: (map['is_recurring'] as bool?) ?? false,
      isDaily: (map['is_daily'] as bool?) ?? false,
      order: (map['order'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  DailyTask copyWith({
    String? id,
    String? shortTermGoalId,
    String? taskName,
    int? dayOfWeek,
    DateTime? specificDate,
    bool? isRecurring,
    bool? isDaily,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyTask(
      id: id ?? this.id,
      shortTermGoalId: shortTermGoalId ?? this.shortTermGoalId,
      taskName: taskName ?? this.taskName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      specificDate: specificDate ?? this.specificDate,
      isRecurring: isRecurring ?? this.isRecurring,
      isDaily: isDaily ?? this.isDaily,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get dayName {
    if (isDaily) return 'Daily';
    if (dayOfWeek == null) return 'Specific Date';
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek!];
  }
}

// Model for tracking daily task completion
class DailyTaskCompletion {
  final String id;
  final String dailyTaskId;
  final DateTime date;
  final bool isCompleted;
  final DateTime createdAt;

  DailyTaskCompletion({
    required this.id,
    required this.dailyTaskId,
    required this.date,
    required this.isCompleted,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'daily_task_id': dailyTaskId,
      'date': date.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyTaskCompletion.fromMap(Map<String, dynamic> map) {
    return DailyTaskCompletion(
      id: map['id'] as String,
      dailyTaskId: map['daily_task_id'] as String,
      date: DateTime.parse(map['date'] as String),
      isCompleted: (map['is_completed'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

