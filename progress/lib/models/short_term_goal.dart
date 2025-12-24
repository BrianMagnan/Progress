import 'goal.dart';

class ShortTermGoal {
  final String id;
  final String title;
  final String? description;
  final GoalStatus status;
  final GoalDifficulty? difficulty;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int order;

  ShortTermGoal({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.difficulty,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.order = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.value,
      'difficulty': difficulty?.value,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'order': order,
    };
  }

  factory ShortTermGoal.fromMap(Map<String, dynamic> map) {
    return ShortTermGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: goalStatusFromValue(map['status'] as int),
      difficulty: map['difficulty'] != null
          ? goalDifficultyFromValue(map['difficulty'] as int)
          : null,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      order: (map['order'] as int?) ?? 0,
    );
  }

  ShortTermGoal copyWith({
    String? id,
    String? title,
    String? description,
    GoalStatus? status,
    GoalDifficulty? difficulty,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? order,
  }) {
    return ShortTermGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
    );
  }
}

