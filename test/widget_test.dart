import 'package:flutter_test/flutter_test.dart';
import 'package:taskmanager/features/tasks/domain/task.dart';

void main() {
  test('Task serializes API fields correctly', () {
    final task = Task.fromJson({
      'id': 7,
      'title': 'Prepare release',
      'is_completed': false,
      'priority': 'High',
      'category': 'Work',
      'due_date': '2026-12-01T12:00:00',
      'created_at': '2026-11-01T12:00:00',
    });

    expect(task.id, 7);
    expect(task.priority, TaskPriority.high);
    expect(task.category, TaskCategory.work);
    expect(task.toRequestJson()['title'], 'Prepare release');
    expect(task.toRequestJson().containsKey('id'), isFalse);
  });
}
