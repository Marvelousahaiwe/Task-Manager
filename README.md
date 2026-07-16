# Task Manager

A Flutter task management application with local persistence, search, and state management.

## Architecture

The app follows a **layered architecture** that separates concerns into three main layers:

### Data Layer (`lib/data/`)
- **Models** (`task_model.dart`): Data class representing a task with serialization (`toMap`/`fromMap`) for Hive storage.
- **Repository** (`task_repository.dart`): Singleton repository handling Hive box operations (open, read, write). Abstracts all persistence logic behind a clean interface.

### Presentation Layer (`lib/presentation/`)
- **Providers** (`task_provider.dart`): Riverpod state management using `StateNotifier<TaskListState>`. Exposes:
  - `taskListNotifierProvider` — full task list with loading/error state
  - `filteredTasksProvider` — derived provider that filters tasks by search query
  - `searchQueryProvider` — reactive search input state
- **Screens** (`screens/`): UI pages (`TaskListScreen`, `AddEditTaskScreen`). Screens are `ConsumerStatefulWidget`s that wire providers to UI.
- **Widgets** (`widgets/`): Reusable UI components (`TaskCard`, `EmptyState`).

### State Management (Riverpod)
- `StateNotifier` pattern for the task list with `copyWith` immutability
- Derived providers (`filteredTasksProvider`) for computed state
- Providers auto-dispose and properly handle lifecycle

### Data Flow
```
UI (ConsumerWidget)
    ↓ reads/writes
Riverpod Providers
    ↓ calls
TaskRepository (singleton)
    ↓ reads/writes
Hive (local storage)
```

## Features
- Create, edit, delete tasks with title/description
- Toggle completion status via checkbox
- Search tasks by title or description (real-time filtering)
- Pull-to-refresh to reload from storage
- Persistent storage via Hive (survives app restarts)
- Empty state when no tasks exist
- Delete confirmation dialog
- Loading and error states with retry

## Dependencies
- **flutter_riverpod** — state management
- **hive / hive_flutter** — local persistence
- **uuid** — unique task IDs
