class SubSkill {
  final String id;
  final String skillId;
  final String name;
  final int? skillLevel; // 1-10 confidence scale
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubSkill({
    required this.id,
    required this.skillId,
    required this.name,
    this.skillLevel,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skill_id': skillId,
      'name': name,
      'skill_level': skillLevel,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SubSkill.fromMap(Map<String, dynamic> map) {
    return SubSkill(
      id: map['id'] as String,
      skillId: map['skill_id'] as String,
      name: map['name'] as String,
      skillLevel: map['skill_level'] as int?,
      order: (map['order'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SubSkill copyWith({
    String? id,
    String? skillId,
    String? name,
    int? skillLevel,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubSkill(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      name: name ?? this.name,
      skillLevel: skillLevel ?? this.skillLevel,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
