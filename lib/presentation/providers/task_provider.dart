import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

// ---- State ----
// Holds the full task list plus loading/error indicators. The
// operationError field captures transient errors from mutations
// (add/update/delete) separately from the load error so the UI can
// show a snackbar without replacing the entire screen.
// operationMessage carries success feedback (e.g. "Task completed")
// for brief toast-style display.
class TaskListState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;
  final String? operationError;
  final String? operationMessage;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.operationError,
    this.operationMessage,
  });

  TaskListState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
    String? operationError,
    String? operationMessage,
    bool clearOperationError = false,
    bool clearOperationMessage = false,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      operationError:
          clearOperationError ? null : (operationError ?? this.operationError),
      operationMessage: clearOperationMessage
          ? null
          : (operationMessage ?? this.operationMessage),
    );
  }
}

// ---- Notifier ----
// Uses optimistic updates: the UI state changes immediately (fast UX),
// then the change is persisted to Hive. If persistence fails, the
// operationError is set so the user can retry. The in-memory state
// remains correct either way.
//
// The undo-delete pattern stores the last deleted task temporarily
// so the UI can restore it on "Undo" without re-fetching from storage.
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository _repository;
  TaskModel? _lastDeletedTask;

  TaskListNotifier(this._repository) : super(const TaskListState());

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repository.loadTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load tasks');
    }
  }

  Future<void> addTask(TaskModel task) async {
    final updatedTasks = [...state.tasks, task];
    state = state.copyWith(tasks: updatedTasks);
    try {
      await _repository.saveTasks(updatedTasks);
    } catch (e) {
      state = state.copyWith(operationError: 'Failed to save task');
    }
  }

  Future<void> updateTask(TaskModel task) async {
    final updatedTasks =
        state.tasks.map((t) => t.id == task.id ? task : t).toList();
    state = state.copyWith(tasks: updatedTasks);
    try {
      await _repository.saveTasks(updatedTasks);
    } catch (e) {
      state = state.copyWith(operationError: 'Failed to save changes');
    }
  }

  Future<void> deleteTask(String id) async {
    _lastDeletedTask = state.tasks.where((t) => t.id == id).firstOrNull;
    final updatedTasks = state.tasks.where((t) => t.id != id).toList();
    state = state.copyWith(tasks: updatedTasks);
    try {
      await _repository.saveTasks(updatedTasks);
    } catch (e) {
      state = state.copyWith(operationError: 'Failed to delete task');
    }
  }

  Future<void> undoDelete() async {
    final task = _lastDeletedTask;
    if (task == null) return;
    _lastDeletedTask = null;
    final updatedTasks = [...state.tasks, task];
    state = state.copyWith(tasks: updatedTasks);
    try {
      await _repository.saveTasks(updatedTasks);
    } catch (e) {
      state = state.copyWith(operationError: 'Failed to restore task');
    }
  }

  Future<void> toggleCompletion(String id) async {
    // Capture the previous state before mutating so we can show the
    // correct toast message (completed vs. uncompleted).
    final wasCompleted =
        state.tasks.firstWhere((t) => t.id == id).isCompleted;
    final message =
        wasCompleted ? 'Task marked incomplete' : 'Task completed';

    final updatedTasks = state.tasks.map((t) {
      if (t.id == id) {
        return t.copyWith(isCompleted: !t.isCompleted);
      }
      return t;
    }).toList();
    state = state.copyWith(tasks: updatedTasks, operationMessage: message);
    try {
      await _repository.saveTasks(updatedTasks);
    } catch (e) {
      state = state.copyWith(operationError: 'Failed to update task status');
    }
  }

  // Clears the transient operation error after the UI has displayed it.
  void clearOperationError() {
    state = state.copyWith(clearOperationError: true);
  }

  // Clears the transient operation message after the UI has displayed it.
  void clearOperationMessage() {
    state = state.copyWith(clearOperationMessage: true);
  }
}

// ---- Providers ----

// Repository is a singleton, so Provider always returns the same instance.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// The notifier auto-loads tasks on creation via the provider's callback.
final taskListNotifierProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final repository = ref.read(taskRepositoryProvider);
  final notifier = TaskListNotifier(repository);
  notifier.loadTasks();
  return notifier;
});

// Tracks the current search query string.
final searchQueryProvider = StateProvider<String>((ref) => '');

// Derived provider: re-computes the filtered list whenever the query
// or the task list changes. Filters case-insensitively across both
// title and description. Returns the full list when query is empty so
// no unnecessary allocations occur.
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final tasks = ref.watch(taskListNotifierProvider).tasks;
  if (query.isEmpty) return tasks;
  return tasks.where((task) {
    return task.title.toLowerCase().contains(query) ||
        task.description.toLowerCase().contains(query);
  }).toList();
});
