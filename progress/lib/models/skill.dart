class Skill {
  final String id;
  final String categoryId;
  final String name;
  final int? skillLevel; // 1-10 confidence scale
  final DateTime createdAt;
  final DateTime updatedAt;

  Skill({
    required this.id,
    required this.categoryId,
    required this.name,
    this.skillLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'skill_level': skillLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      skillLevel: map['skill_level'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Skill copyWith({
    String? id,
    String? categoryId,
    String? name,
    int? skillLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Skill(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      skillLevel: skillLevel ?? this.skillLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

