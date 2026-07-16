import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/task_model.dart';
import '../providers/task_provider.dart';

// Reusable screen for creating, editing, and viewing tasks.
// Mode is determined by the combination of [task] and [readOnly]:
//   task=null, readOnly=false → Create mode
//   task!=null, readOnly=false → Edit mode
//   task!=null, readOnly=true  → View mode (fields disabled, status card shown)
class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? task;
  final bool readOnly;

  const AddEditTaskScreen({
    super.key,
    this.task,
    this.readOnly = false,
  });

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null && !widget.readOnly;
  bool get _isViewing => widget.task != null && widget.readOnly;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Safety check: the form key must be mounted before accessing
    // currentState. This can fail if the widget tree hasn't built yet.
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final updated = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        await ref.read(taskListNotifierProvider.notifier).updateTask(updated);
      } else {
        final task = TaskModel(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        await ref.read(taskListNotifierProvider.notifier).addTask(task);
      }

      // Check mounted before navigating — the widget could be
      // disposed if the user pressed back during the async save.
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Show a transient error snackbar; the in-memory state may have
      // been optimistically updated but persistence failed.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isViewing ? 'Task Details' : _isEditing ? 'Edit Task' : 'New Task',
        ),
        actions: [
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _isSaving ? null : _save,
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _isViewing
                  ? 'Task information'
                  : _isEditing
                      ? 'Update your task'
                      : 'Create a new task',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              readOnly: widget.readOnly,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                filled: !widget.readOnly,
              ),
              autofocus: !_isEditing && !widget.readOnly,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: widget.readOnly ? null : 120,
              validator: widget.readOnly
                  ? null
                  : (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              readOnly: widget.readOnly,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add some details...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
                filled: true,
              ),
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            if (_isViewing) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            widget.task!.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: widget.task!.isCompleted
                                ? Colors.green
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.task!.isCompleted
                                ? 'Completed'
                                : 'In Progress',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
