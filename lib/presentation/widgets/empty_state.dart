import 'package:flutter/material.dart';

// Search-aware empty state. When [query] is non-null and non-empty,
// it shows "No results found" instead of the default "No tasks yet"
// message, passing the query through so the user knows what was searched.
class EmptyState extends StatelessWidget {
  final String? query;

  const EmptyState({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearch = query?.isNotEmpty == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              ),
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.task_alt_rounded,
                size: 40,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearch ? 'No results found' : 'No tasks yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'No tasks match "$query"'
                  : 'Tap + to add your first task',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
