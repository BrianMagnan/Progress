class ProgressLog {
  final String id;
  final String goalId;
  final DateTime date;
  final String? notes; // What you practiced
  final String? learned; // What you learned
  final String? struggledWith; // What you struggled with
  final String? nextSteps; // What you want to do next
  final int? durationMinutes; // Optional: how long you worked
  final DateTime createdAt;

  ProgressLog({
    required this.id,
    required this.goalId,
    required this.date,
    this.notes,
    this.learned,
    this.struggledWith,
    this.nextSteps,
    this.durationMinutes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'date': date.toIso8601String(),
      'notes': notes,
      'learned': learned,
      'struggled_with': struggledWith,
      'next_steps': nextSteps,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProgressLog.fromMap(Map<String, dynamic> map) {
    return ProgressLog(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      learned: map['learned'] as String?,
      struggledWith: map['struggled_with'] as String?,
      nextSteps: map['next_steps'] as String?,
      durationMinutes: map['duration_minutes'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ProgressLog copyWith({
    String? id,
    String? goalId,
    DateTime? date,
    String? notes,
    String? learned,
    String? struggledWith,
    String? nextSteps,
    int? durationMinutes,
    DateTime? createdAt,
  }) {
    return ProgressLog(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      learned: learned ?? this.learned,
      struggledWith: struggledWith ?? this.struggledWith,
      nextSteps: nextSteps ?? this.nextSteps,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

