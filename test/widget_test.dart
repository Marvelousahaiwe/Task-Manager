import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krystall_task/app.dart';
import 'package:krystall_task/data/models/task_model.dart';
import 'package:krystall_task/data/repositories/task_repository.dart';
import 'package:krystall_task/presentation/providers/task_provider.dart';

class FakeTaskRepository implements TaskRepository {
  final List<TaskModel> tasks = [];

  @override
  Future<List<TaskModel>> loadTasks() async {
    return tasks;
  }

  @override
  Future<void> saveTasks(List<TaskModel> tasks) async {
    this.tasks.clear();
    this.tasks.addAll(tasks);
  }
}

void main() {
  late FakeTaskRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeTaskRepository();
  });

  testWidgets('Task Manager smoke test - empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeRepository),
        ],
        child: const App(),
      ),
    );

    // Verify empty state is shown
    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Tap + to add your first task'), findsOneWidget);
  });

  testWidgets('Task Manager - add a task', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeRepository),
        ],
        child: const App(),
      ),
    );

    // Tap the floating action button to open New Task screen
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify we are on the New Task screen
    expect(find.text('New Task'), findsOneWidget);

    // Enter title and description
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Test Task Title');
    await tester.enterText(textFields.at(1), 'Test Task Description');

    // Tap Save button
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify we are back on the main screen and task is in the list
    expect(find.text('No tasks yet'), findsNothing);
    expect(find.text('Test Task Title'), findsOneWidget);
    expect(find.text('Test Task Description'), findsOneWidget);
  });
}
