# Task Manager

A modern Flutter task management app built with Riverpod and Hive, featuring clean layered architecture, local persistence, real-time search, CRUD operations, reusable widgets, immutable state management, and responsive UI. Demonstrates scalable Flutter development using best practices and modern design patterns.

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

## App Download
- Click to download app [Download](https://drive.google.com/drive/folders/1rwzCm2SB_I7ub5-B5qGastgsuIwgZEJmS)


## Installation

### 1. Clone the repo

```bash
git clone https://github.com/Marvelousahaiwe/Task-Manager.git
cd Task-Manager
```

### 2. Run pub get

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run
```

## Developer

- [Marvelous Ahaiwe](https://www.linkedin.com/in/marvelous-ahaiwe-31488b184)