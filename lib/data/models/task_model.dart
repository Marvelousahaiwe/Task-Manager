// TaskModel: immutable-ish data class representing a single task.
// Uses copyWith for controlled mutation and toMap/fromMap for
// serialization to Hive (which stores Map<String, dynamic>).

class TaskModel {
  final String id;
  String title;
  String description;
  bool isCompleted;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Creates a new TaskModel with only the specified fields changed.
  // The original is unchanged — this enables immutable state updates.
  TaskModel copyWith({
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  // Null-safe deserialization: missing keys gracefully default to
  // safe values rather than throwing. This handles legacy data or
  // schema additions without migration.
  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        isCompleted: map['isCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
