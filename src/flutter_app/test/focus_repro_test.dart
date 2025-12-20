import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';

class MockMarkdownPersistence extends Mock implements MarkdownPersistenceService {
    @override
    Future<void> saveTask(Task t, Project p) async {}
}

class MockStorageRepository extends Mock implements StorageRepository {
  // Stub basic methods
  @override
  Future<void> init() async {}
  @override
  Stream<void> get onDataChanged => const Stream.empty();
  @override
  Future<List<Project>> getAllProjects() async => [];
  @override
  Future<void> saveProject(Project p) async {}
  @override
  Future<void> saveTask(Task t) async {}
  @override
  Future<void> deleteTask(String id) async {}
}

// We need a real DataService or a realistic mock.
// Since DataService depends on StorageRepository, we can mock the repository.
// Using real DataService + MockRepository is best to test logic.


void main() {
  testWidgets('Right Arrow navigation focuses new task', (WidgetTester tester) async {
    // Setup
    final mockStorage = MockStorageRepository();
    final mockMarkdown = MockMarkdownPersistence();
    final dataService = DataService(mockStorage, mockMarkdown);
    
    // Create initial project
    dataService.addProject('Project A');
    final project = dataService.projects.first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWithValue(dataService),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Select the project "Project A"
    // Tap on it to ensure focus
    final projectFinder = find.widgetWithText(TextField, 'Project A');
    expect(projectFinder, findsOneWidget);
    await tester.tap(projectFinder);
    await tester.pumpAndSettle();

    // Verify Project TextField has focus
    final projectField = tester.widget<TextField>(projectFinder);
    expect(projectField.focusNode!.hasFocus, isTrue, reason: "Project A should be focused");

    // 2. Press Right Arrow
    // This should trigger _changeColumn -> addTask -> focus new task
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(); // Start animation/creation
    await tester.pump(const Duration(milliseconds: 60)); // Wait for our 50ms delay
    await tester.pumpAndSettle(); // Settle everything

    // 3. Verify New Task Created
    expect(dataService.projects.first.tasks, isNotEmpty);
    final newTask = dataService.projects.first.tasks.first;
    expect(newTask.title, isEmpty); // Should be empty "New Item" placeholder (or empty string)

    // 4. Verify Focus Moved to New Task
    final taskFinder = find.descendant(
        of: find.byType(EditableColumn).at(1), // Second column
        matching: find.byType(TextField)
    );
    expect(taskFinder, findsOneWidget);
    
    final taskField = tester.widget<TextField>(taskFinder);
    expect(taskField.focusNode!.hasFocus, isTrue, reason: "New Task should be focused");
    
    // 5. Verify Project lost focus
    expect(projectField.focusNode!.hasFocus, isFalse, reason: "Project A should lose focus");
  });
}
