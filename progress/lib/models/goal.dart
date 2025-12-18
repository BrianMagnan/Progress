enum GoalStatus {
  notStarted,
  inProgress,
  completed,
}

extension GoalStatusExtension on GoalStatus {
  String get displayName {
    switch (this) {
      case GoalStatus.notStarted:
        return 'Not Started';
      case GoalStatus.inProgress:
        return 'In Progress';
      case GoalStatus.completed:
        return 'Completed';
    }
  }

  int get value {
    switch (this) {
      case GoalStatus.notStarted:
        return 0;
      case GoalStatus.inProgress:
        return 1;
      case GoalStatus.completed:
        return 2;
    }
  }
}

GoalStatus goalStatusFromValue(int value) {
  switch (value) {
    case 0:
      return GoalStatus.notStarted;
    case 1:
      return GoalStatus.inProgress;
    case 2:
      return GoalStatus.completed;
    default:
      return GoalStatus.notStarted;
  }
}

enum GoalDifficulty {
  easy,
  medium,
  hard,
}

extension GoalDifficultyExtension on GoalDifficulty {
  String get displayName {
    switch (this) {
      case GoalDifficulty.easy:
        return 'Easy';
      case GoalDifficulty.medium:
        return 'Medium';
      case GoalDifficulty.hard:
        return 'Hard';
    }
  }

  int get value {
    switch (this) {
      case GoalDifficulty.easy:
        return 0;
      case GoalDifficulty.medium:
        return 1;
      case GoalDifficulty.hard:
        return 2;
    }
  }
}

GoalDifficulty goalDifficultyFromValue(int value) {
  switch (value) {
    case 0:
      return GoalDifficulty.easy;
    case 1:
      return GoalDifficulty.medium;
    case 2:
      return GoalDifficulty.hard;
    default:
      return GoalDifficulty.medium;
  }
}

class Goal {
  final String id;
  final String subSkillId;
  final String title;
  final String? description;
  final GoalStatus status;
  final GoalDifficulty? difficulty;
  final int? estimatedHours; // Optional estimated time
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  Goal({
    required this.id,
    required this.subSkillId,
    required this.title,
    this.description,
    required this.status,
    this.difficulty,
    this.estimatedHours,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sub_skill_id': subSkillId,
      'title': title,
      'description': description,
      'status': status.value,
      'difficulty': difficulty?.value,
      'estimated_hours': estimatedHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      subSkillId: map['sub_skill_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: goalStatusFromValue(map['status'] as int),
      difficulty: map['difficulty'] != null
          ? goalDifficultyFromValue(map['difficulty'] as int)
          : null,
      estimatedHours: map['estimated_hours'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Goal copyWith({
    String? id,
    String? subSkillId,
    String? title,
    String? description,
    GoalStatus? status,
    GoalDifficulty? difficulty,
    int? estimatedHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      subSkillId: subSkillId ?? this.subSkillId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

