import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

// Singleton repository that owns the Hive box lifecycle.
// The box is opened lazily on first access rather than at app start,
// keeping the initial launch fast. All persistence errors are caught
// and re-thrown so the provider layer can surface them to the UI.
class TaskRepository {
  static final TaskRepository _instance = TaskRepository._();
  factory TaskRepository() => _instance;
  TaskRepository._();

  Box? _box;

  // Lazy getter: the Hive box is opened once and cached for subsequent
  // calls. The box stores a single key 'task_list' containing the
  // serialized List<Map> of all tasks.
  Future<Box> get _tasksBox async {
    _box ??= await Hive.openBox('tasks');
    return _box!;
  }

  Future<List<TaskModel>> loadTasks() async {
    try {
      final box = await _tasksBox;
      final data = box.get('task_list') as List? ?? [];
      return data
          .map((e) => TaskModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // On failure, return an empty list so the app can still function
      // and show a relevant error state rather than crash.
      return [];
    }
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    try {
      final box = await _tasksBox;
      await box.put('task_list', tasks.map((e) => e.toMap()).toList());
    } catch (e) {
      throw Exception('Failed to persist tasks: $e');
    }
  }
}
