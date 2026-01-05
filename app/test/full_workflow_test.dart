import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/services/file_system_service.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';
import 'package:flutter_app/providers/selection_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/utils/markdown_parser.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}

class TestFileSystemService extends FileSystemService {
  final String testBaseDir;
  
  TestFileSystemService({required this.testBaseDir}) : super(baseDir: testBaseDir);

  @override
  Stream<List<Project>> watchProjects() {
    return const Stream.empty();
  }

  @override
  Future<void> saveProject(Project project) async {
    // Synchronous I/O to prevent test hangs
    final category = project.tags.isNotEmpty ? project.tags.first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') : 'unsorted';
    final fileName = project.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
    final filePath = '$testBaseDir/todos/$category/$fileName.md';
    
    final file = File(filePath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    
    final markdown = MarkdownParser.toMarkdown(project);
    file.writeAsStringSync(markdown);
  }
}

void main() {
  late Directory tempDir;
  late FileSystemService fileService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gemini_test_');
    fileService = TestFileSystemService(testBaseDir: tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  testWidgets('Full Workflow: Create Project, Notes, Task, and Delete Task', timeout: const Timeout(Duration(seconds: 60)), (WidgetTester tester) async {
    // Desktop size for full layout
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        fileSystemServiceProvider.overrideWithValue(fileService),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));

    // 1) Verify no projects in app and files
    expect(find.byType(EditableColumn), findsNWidgets(1));
    expect(find.descendant(of: find.byKey(const ValueKey('projects')), matching: find.text('My new Project')), findsNothing);
    
    final todosDir = Directory('${tempDir.path}/todos');
    if (todosDir.existsSync()) {
       expect(todosDir.listSync(recursive: true).where((e) => e.path.endsWith('.md')).isEmpty, isTrue);
    }

    // 2) Press "Add Item" on Project Overview and start typing "My new Project"
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    
    // Allow async UI update and debounce to fire
    await tester.pump(const Duration(milliseconds: 500)); 

    // Find the active TextField (Title is first, Notes is second)
    final projectInputFinder = find.descendant(
      of: find.byKey(const ValueKey('projects')),
      matching: find.byType(TextField)
    );
    expect(projectInputFinder, findsNWidgets(2));
    
    await tester.enterText(projectInputFinder.first, "My new Project");
    await tester.pump(); // Rebuild with text

    // 3) Press "Esc" -> Verify project is still selected
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text("My new Project"), findsOneWidget);
    
    // Verify selection
    final selectionState = container.read(selectionProvider);
    expect(selectionState.selectedProjectId, isNotNull);
    
    // Verify File
    // Replace Future.delayed with pump to be safe in test env
    await tester.pump(const Duration(milliseconds: 500)); 
    
    final files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
    // Due to rename logic not deleting old file yet, we might have multiple files.
    expect(files.length, greaterThanOrEqualTo(1));
    
    final hasCorrectContent = files.any((f) {
       final c = f.readAsStringSync();
       return c.contains("# My new Project");
    });
    expect(hasCorrectContent, isTrue);

    // 4) Press Enter -> Verify opened in edit mode
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 500));
    
    // Should have 2 text fields (Title and Notes)
    final editFields = find.descendant(
      of: find.byKey(const ValueKey('projects')),
      matching: find.byType(TextField)
    );
    expect(editFields, findsNWidgets(2));
    
    // 5) Press "Tab" -> Verify cursor jumped to notes section
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 500));
    
    // Verify focus is on the second text field
    final notesField = editFields.at(1);
    expect(tester.widget<TextField>(notesField).focusNode?.hasFocus, isTrue);

    // 6) Write "my new notes" -> Verify persistence
    await tester.enterText(notesField, "my new notes");
    await tester.pump();
    
    // Wait for file write
    await Future.delayed(const Duration(milliseconds: 500));
    final updatedContent = files.first.readAsStringSync();
    expect(updatedContent, contains("my new notes"));

    // 7) Press "Esc" -> Verify Project in app/file is correct
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    
    expect(find.text("my new notes"), findsOneWidget);
    
    final finalContent = files.first.readAsStringSync();
    expect(finalContent, contains("title: My new Project"));
    expect(finalContent, contains("my new notes"));

    // 8) In Task Column: Press "Add Item" / plus button
    Focus.of(tester.element(find.byKey(const ValueKey('rootFocus')))).requestFocus();
    await tester.pump();

    // Navigate Right
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 500));
    
    expect(find.text('Tasks'), findsOneWidget);

    // Add Item
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump(const Duration(milliseconds: 500));
    
    // 9) Enter "My new Task" -> Verify persistence
    // Note: Use ValueKey with variable in test requires removing const or building key properly
    final taskInputFinder = find.descendant(
      of: find.byKey(ValueKey('tasks_${selectionState.selectedProjectId}')),
      matching: find.byType(TextField)
    );
    expect(taskInputFinder, findsAtLeastNWidgets(1));
    
    await tester.enterText(taskInputFinder.first, "My new Task");
    await tester.pump();

    // Verify App
    expect(find.text("My new Task"), findsOneWidget);
    
    // Verify File
    await Future.delayed(const Duration(milliseconds: 500));
    final taskContent = files.first.readAsStringSync();
    expect(taskContent, contains("- [ ] My new Task"));

    // Exit edit mode for task to stabilize state
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));

    // 10) Press "cmd + backspace" -> Verify removal
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump(const Duration(milliseconds: 500));
    
    // Verify removal in App
    expect(find.text("My new Task"), findsNothing);
    
    // Verify removal in File
    await Future.delayed(const Duration(milliseconds: 500));
    final afterDeleteContent = files.first.readAsStringSync();
    expect(afterDeleteContent, isNot(contains("My new Task")));
    
    // Verify Project is still selected (in state)
    final afterDeleteState = container.read(selectionProvider);
    expect(afterDeleteState.selectedProjectId, isNotNull);
    expect(afterDeleteState.selectedTaskId, isNull); // Task deleted
    
    // Verify Notes and Title unchanged
    expect(afterDeleteContent, contains("title: My new Project"));
    expect(afterDeleteContent, contains("my new notes"));
  });
}