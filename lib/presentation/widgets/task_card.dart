import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

// TaskCard displays a single task with:
//   - Animated circular checkbox (toggle completion)
//   - Highlighted title/description when a search query is active
//   - Three-dot popup menu (View / Edit / Delete)
// The card uses AnimatedContainer to smoothly transition between
// completed and incomplete visual states (color, shadow, border).
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final String query;
  final VoidCallback onToggle;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.query = '',
    required this.onToggle,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? Colors.transparent
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isCompleted ? 0.02 : 0.06),
            blurRadius: isCompleted ? 0 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 15,
                          color: theme.colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onView,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHighlightedText(
                        task.title,
                        query,
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildHighlightedText(
                          task.description,
                          query,
                          theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    onView();
                  case 'edit':
                    onEdit();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.visibility_outlined),
                    title: Text('View'),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title:
                        Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
              icon: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a Text or RichText widget. When a search query is present,
  // it splits the text around every occurrence of the query
  // (case-insensitive) and wraps matching segments in a highlighted
  // yellow background + bold weight so the user can visually locate
  // matches in the list. Falls back to plain Text when there are no
  // matches or no query to avoid unnecessary RichText overhead.
  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle? style, {
    int maxLines = 1,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <int>[];
    int start = 0;

    // Collect all start indices where the query appears in the text.
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;
      matches.add(index);
      start = index + lowerQuery.length;
    }

    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Build a list of TextSpans: non-matching segments are plain,
    // matching segments get a highlight style applied.
    final spans = <TextSpan>[];
    int cursor = 0;
    for (final matchIndex in matches) {
      if (matchIndex > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, matchIndex)));
      }
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + lowerQuery.length),
        style: style?.copyWith(
          backgroundColor: Colors.yellow.withValues(alpha: 0.35),
          fontWeight: FontWeight.w700,
        ),
      ));
      cursor = matchIndex + lowerQuery.length;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
