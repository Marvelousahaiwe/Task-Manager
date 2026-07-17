import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import 'add_edit_task_screen.dart';

// Main screen showing the task list with search, swipe-to-delete,
// and a floating action button for creating new tasks.
//
// Search flow:
//   1. User taps the search icon in the app bar
//   2. AnimatedSize expands the search bar with auto-focus
//   3. Input is debounced (250ms) to avoid excessive filtering
//   4. The debounced value updates searchQueryProvider
//   5. filteredTasksProvider recomputes and the UI reacts
//
// Delete flow:
//   Dismissible + confirmDismiss dialog → onDismissed deletes from
//   state+storage and shows an undo snackbar.
//   The popup menu Delete option also goes through confirmDismiss dialog.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;


  // @override
  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Debounces search input: waits 250ms after the user stops typing
  // before updating the provider. This prevents jank from rapid
  // filtering while still feeling responsive.
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      ref.read(searchQueryProvider.notifier).state = value.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).state = '';
    _searchFocusNode.unfocus();
  }

  Future<bool> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _openView(String taskId) {
    final tasks = ref.read(taskListNotifierProvider).tasks;
    final task = tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => _throwTaskNotFound(taskId),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(task: task, readOnly: true),
      ),
    );
  }

  void _openAddEdit({String? taskId}) {
    final task = taskId != null
        ? ref
              .read(taskListNotifierProvider)
              .tasks
              .firstWhere(
                (t) => t.id == taskId,
                orElse: () => _throwTaskNotFound(taskId),
              )
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
    );
  }

  Never _throwTaskNotFound(String id) {
    throw StateError('Task with id $id not found in state');
  }

  // Popup menu delete: shows confirmation dialog, then deletes if
  // confirmed and shows an undo snackbar.
  void _deleteWithDialog(String id) async {
    final confirmed = await _confirmDelete(id);
    if (!mounted) return;
    if (!confirmed) return;

    ref.read(taskListNotifierProvider.notifier).deleteTask(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(taskListNotifierProvider.notifier).undoDelete();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for operation errors and success messages from the
    // notifier and display them as transient floating snackbars.
    // Each is cleared after display so they don't re-appear.
    ref.listen<TaskListState>(taskListNotifierProvider, (_, next) {
      final error = next.operationError;
      if (error != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.read(taskListNotifierProvider.notifier).clearOperationError();
      }
      final message = next.operationMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.read(taskListNotifierProvider.notifier).clearOperationMessage();
      }
    });

    final theme = Theme.of(context);
    final state = ref.watch(taskListNotifierProvider);
    final query = ref.watch(searchQueryProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);

    return Scaffold(
      appBar: AppBar(title: Center(child: const Text('Tasks'))),
      body: Column(
        children: [
          // AnimatedSize smoothly expands/collapses the search bar.
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: _clearSearch,
                              )
                            : null,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody(theme, state, query, filteredTasks)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    TaskListState state,
    String query,
    List<TaskModel> filteredTasks,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(taskListNotifierProvider.notifier).loadTasks(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredTasks.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyState(query: query),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(taskListNotifierProvider.notifier).loadTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                  SizedBox(height: 2),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // confirmDismiss pauses the dismiss animation and shows a
            // confirmation dialog. Returning false cancels the swipe.
            confirmDismiss: (_) => _confirmDelete(task.id),
            // onDismissed is called only after confirmDismiss returns
            // true. At this point the visual dismiss has completed and
            // we commit the deletion to state + storage.
            onDismissed: (_) {
              ref.read(taskListNotifierProvider.notifier).deleteTask(task.id);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Task deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(taskListNotifierProvider.notifier).undoDelete();
                    },
                  ),
                ),
              );
            },
            child: TaskCard(
              task: task,
              query: query,
              onToggle: () => ref
                  .read(taskListNotifierProvider.notifier)
                  .toggleCompletion(task.id),
              onView: () => _openView(task.id),
              onEdit: () => _openAddEdit(taskId: task.id),
              onDelete: () => _deleteWithDialog(task.id),
            ),
          );
        },
      ),
    );
  }
}
