enum TaskPriority { low, medium, high }

enum TaskCategory { work, personal, health, finance, education, shopping, travel, others }

enum TaskSort { dueDate, priority, createdDate }

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.priority,
    required this.category,
    required this.dueDate,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime? dueDate;
  final DateTime createdAt;

  Task copyWith({bool? isCompleted}) => Task(
        id: id, title: title, description: description,
        isCompleted: isCompleted ?? this.isCompleted, priority: priority,
        category: category, dueDate: dueDate, createdAt: createdAt,
      );

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        isCompleted: json['is_completed'] as bool? ?? false,
        priority: TaskPriority.values.byName((json['priority'] as String? ?? 'Medium').toLowerCase()),
        category: TaskCategory.values.byName((json['category'] as String? ?? 'Work').toLowerCase()),
        dueDate: json['due_date'] == null ? null : DateTime.parse(json['due_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'description': description,
        'is_completed': isCompleted, 'priority': priority.name[0].toUpperCase() + priority.name.substring(1),
        'category': category.name[0].toUpperCase() + category.name.substring(1),
        'due_date': dueDate?.toIso8601String(), 'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toRequestJson() => Map.of(toJson())..removeWhere((key, _) => key == 'id' || key == 'created_at');
}
