import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/services/file_system_service.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';
import 'package:flutter_app/providers/selection_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/utils/markdown_parser.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries, bool? savePortToConfig}) async {}

  @override
  Future<void> stop() async {}
}

class TestFileSystemService extends FileSystemService {
  final String testBaseDir;
  final StreamController<List<Node>> _controller = StreamController<List<Node>>.broadcast();

  TestFileSystemService({required this.testBaseDir}) : super(baseDir: testBaseDir);

  @override
  Stream<List<Node>> watchNodes() {
    return _controller.stream;
  }

  /// Simulates an external file change by re-reading all files and emitting the new list.
  void reloadFromDisk() {
    final todosDir = Directory('$testBaseDir/todos');
    if (!todosDir.existsSync()) {
      _controller.add([]);
      return;
    }

    final nodes = <Node>[];
    final files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));

    for (final file in files) {
      final content = file.readAsStringSync();
      final node = MarkdownParser.parseNode(content);
      nodes.add(node);
    }

    _controller.add(nodes);
  }

  @override
  Future<void> saveNode(Node node) async {
    final category = node.tags.isNotEmpty ? node.tags.first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') : 'unsorted';
    final fileName = node.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
    final filePath = '$testBaseDir/todos/$category/$fileName.md';

    final file = File(filePath);

    // Check for existing files with same ID to handle renames
    final todosDir = Directory('$testBaseDir/todos');
    if (todosDir.existsSync()) {
      final existingFiles = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
      for (final existing in existingFiles) {
        if (existing.path == filePath) continue;

        try {
          final content = existing.readAsStringSync();
          final existingNode = MarkdownParser.parseNode(content);
          if (existingNode.id == node.id) {
            existing.deleteSync();
          }
        } catch (e) {
          // Ignore parse errors on other files
        }
      }
    }

    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    final markdown = MarkdownParser.nodeToMarkdown(node);
    file.writeAsStringSync(markdown);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  late Directory tempDir;
  late TestFileSystemService fileService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gemini_test_');
    fileService = TestFileSystemService(testBaseDir: tempDir.path);
  });

  tearDown(() async {
    fileService.dispose();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Full Workflow: Create, Edit, Navigate, External Update, Delete, Space Shortcuts', timeout: const Timeout(Duration(seconds: 120)), (WidgetTester tester) async {
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

    // Give some time for async initData to complete
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));

    // 1) Verify no projects in app and files
    expect(find.byType(EditableColumn), findsNWidgets(1));
    expect(find.descendant(of: find.byKey(const ValueKey('node_0_root')), matching: find.text('My new Project')), findsNothing);

    final todosDir = Directory('${tempDir.path}/todos');
    if (todosDir.existsSync()) {
       expect(todosDir.listSync(recursive: true).where((e) => e.path.endsWith('.md')).isEmpty, isTrue);
    }

    // 2) Press "Cmd+N" -> Start typing "My new Project"
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

    await tester.pump(const Duration(milliseconds: 500));

    final projectInputFinder = find.descendant(
      of: find.byKey(const ValueKey('node_0_root')),
      matching: find.byType(TextField)
    );
    expect(projectInputFinder, findsNWidgets(2)); // Title + Notes

    await tester.enterText(projectInputFinder.first, "My new Project");
    await tester.pump();

    // 3) Press "Esc" -> Verify project is still selected
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500)); // Debounce wait

    expect(find.text("My new Project"), findsAtLeastNWidgets(1));

    final selectionState = container.read(selectionProvider);
    expect(selectionState.selectedProjectId, isNotNull);

    // Verify File Creation
    await tester.pump(const Duration(milliseconds: 500));

    final files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
    expect(files.length, greaterThanOrEqualTo(1));
    expect(files.first.readAsStringSync(), contains("# My new Project"));

    // 4) Press Enter -> Verify opened in edit mode
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 500));

    final editFields = find.descendant(
      of: find.byKey(const ValueKey('node_0_root')),
      matching: find.byType(TextField)
    );
    expect(editFields, findsNWidgets(2));

    // 5) Press "Tab" -> Verify cursor jumped to notes section
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 500));

    final notesField = editFields.at(1);
    expect(tester.widget<TextField>(notesField).focusNode?.hasFocus, isTrue);

    // 6) Write "my new notes" -> Verify persistence
    await tester.enterText(notesField, "my new notes");
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 1100)); // Wait for save
    expect(files.first.readAsStringSync(), contains("my new notes"));

    // 7) Press "Esc" -> Verify Project in app/file is correct
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("my new notes"), findsOneWidget);

    // 8) Navigate Right to create Task
    Focus.of(tester.element(find.byKey(const ValueKey('rootFocus')))).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 1100)); // Wait for auto-create if empty

    expect(find.text('My new Project'), findsAtLeastNWidgets(2));

    // 9) Enter "My new Task"
    final taskInputFinder = find.descendant(
      of: find.byKey(ValueKey('node_1_${selectionState.selectedProjectId}')),
      matching: find.byType(TextField)
    );
    await tester.enterText(taskInputFinder.first, "My new Task");
    await tester.pump();

    // Verify File
    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), contains("- [ ] My new Task"));

    // 9a) Add Notes to Task
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(taskInputFinder.at(1), "Task notes content");
    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), contains("Task notes content"));

    // 9b) Create Subtask (Navigate Right)
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('My new Task'), findsAtLeastNWidgets(2));

    // 9c) Enter Subtask
    final taskId = container.read(selectionProvider).selectedTaskId!;
    final subtaskColKey = ValueKey('node_2_$taskId');
    final subtaskInputFinder = find.descendant(
      of: find.byKey(subtaskColKey),
      matching: find.byType(TextField)
    );

    await tester.enterText(subtaskInputFinder.first, "My new Subtask");
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(subtaskInputFinder.at(1), "Subtask notes content");
    await tester.pump(const Duration(milliseconds: 1100));

    // 9d) Verify Subtask
    expect(files.first.readAsStringSync(), contains("- [ ] My new Subtask"));

    // 10) Delete Task (Navigate Left then delete)
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("My new Task"), findsNothing);

    // 15-17: Navigate back, verify project still selected, edit mode
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 500));

    final stateStep15 = container.read(selectionProvider);
    expect(stateStep15.selectedProjectId, isNotNull, reason: "Project should still be selected");

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.descendant(of: find.byKey(const ValueKey('node_0_root')), matching: find.byType(TextField)), findsNWidgets(2));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));

    // 18: Create new task
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 1100));

    final taskFinderStep18 = find.descendant(
      of: find.byKey(ValueKey('node_1_${stateStep15.selectedProjectId}')),
      matching: find.byType(TextField)
    );
    await tester.enterText(taskFinderStep18.first, "Recreated Task");
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(taskFinderStep18.at(1), "Recreated Notes");
    await tester.pump(const Duration(milliseconds: 1100));

    expect(files.first.readAsStringSync(), contains("- [ ] Recreated Task"));
    expect(files.first.readAsStringSync(), contains("Recreated Notes"));

    // 19: Esc
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));

    // 20: Create subtask
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 1100));

    final taskIdStep20 = container.read(selectionProvider).selectedTaskId;
    expect(taskIdStep20, isNotNull);
    final subtaskFinderStep20 = find.descendant(
      of: find.byKey(ValueKey('node_2_$taskIdStep20')),
      matching: find.byType(TextField)
    );

    await tester.enterText(subtaskFinderStep20.first, "Recreated Subtask");
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(subtaskFinderStep20.at(1), "Recreated Subtask Notes");
    await tester.pump(const Duration(milliseconds: 1100));

    expect(files.first.readAsStringSync(), contains("- [ ] Recreated Subtask"));
    expect(files.first.readAsStringSync(), contains("Recreated Subtask Notes"));

    // 21: Esc
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));

    // 22: Up arrow
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(selectionProvider).selectedTaskId, isNotNull);

    // 23: Edit subtask notes
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(subtaskFinderStep20.at(1), "Recreated Subtask Notes (modified)");
    await tester.pump(const Duration(milliseconds: 1100));

    expect(files.first.readAsStringSync(), contains("Recreated Subtask Notes (modified)"));

    // 24: External file change
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));

    var content = files.first.readAsStringSync();
    var newContent = content.replaceFirst("Recreated Subtask Notes (modified)", "Recreated Subtask Notes (modified from file)");
    files.first.writeAsStringSync(newContent);

    await tester.runAsync(() async {
      fileService.reloadFromDisk();
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text("Recreated Subtask Notes (modified from file)"), findsOneWidget);

    // 25: Delete subtask in file
    content = files.first.readAsStringSync();
    final lines = content.split('\n');
    final newLines = lines.where((l) => !l.contains("Recreated Subtask")).toList();
    files.first.writeAsStringSync(newLines.join('\n'));

    await tester.runAsync(() async {
      fileService.reloadFromDisk();
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text("Recreated Subtask"), findsNothing);

    // 26: Delete task in the file
    content = files.first.readAsStringSync();
    final newLines2 = content.split('\n').where((l) => !l.contains("Recreated Task")).toList();
    files.first.writeAsStringSync(newLines2.join('\n'));

    await tester.runAsync(() async {
      fileService.reloadFromDisk();
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text("Recreated Task"), findsNothing);

    // 27: Delete project
    files.first.deleteSync();

    await tester.runAsync(() async {
      fileService.reloadFromDisk();
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text("My new Project"), findsNothing);

    // SPACE SHORTCUTS (Steps 28 - 31)

    // 28: Space to add new project
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 500));

    final projectSpaceInput = find.descendant(
      of: find.byKey(const ValueKey('node_0_root')),
      matching: find.byType(TextField)
    ).first;

    await tester.enterText(projectSpaceInput, "Project from Space");
    await tester.pump(const Duration(milliseconds: 1100));

    // 29: Navigate right to create task
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 1100));

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 500));

    final taskSpaceInputs = find.descendant(
      of: find.byKey(ValueKey('node_1_${container.read(selectionProvider).selectedProjectId}')),
      matching: find.byType(TextField)
    );
    await tester.enterText(taskSpaceInputs.first, "Task from Space");
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));

    // 31: Verify generated
    final spaceFiles = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
    expect(spaceFiles.first.readAsStringSync(), contains("# Project from Space"));
    expect(spaceFiles.first.readAsStringSync(), contains("- [ ] Task from Space"));

    // 32: Test changing the status
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump(const Duration(milliseconds: 1200));

    expect(spaceFiles.first.readAsStringSync(), contains("- [x] Task from Space"));

    // Toggle via Checkbox click
    final checkbox = find.descendant(
        of: find.byKey(ValueKey('node_1_${container.read(selectionProvider).selectedProjectId}')),
        matching: find.byKey(const Key('item_checkbox'))
    ).last;

    await tester.tap(checkbox);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(spaceFiles.first.readAsStringSync(), contains("- [ ] Task from Space"));
  });

  testWidgets('Slow Typing: Verify no duplicate creation', (WidgetTester tester) async {
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
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));

    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));
    final todosDir = Directory('${tempDir.path}/todos');
    final nodeService = container.read(nodeServiceProvider);

    // --- 1. Slow Type Project ---
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump(const Duration(milliseconds: 500));

    final projectInput = find.descendant(
      of: find.byKey(const ValueKey('node_0_root')),
      matching: find.byType(TextField)
    ).first;

    const part1 = "Slow";
    for (int i = 0; i < part1.length; i++) {
      await tester.enterText(projectInput, part1.substring(0, i + 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
    }

    await simulateKeyDownEvent(LogicalKeyboardKey.space, character: ' ');
    await simulateKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    // Verify we still have only 1 root node
    expect(nodeService.rootNodes.length, 1);

    await tester.enterText(projectInput, "Slow ");

    final projectInputAfterSpace = tester.widget<TextField>(find.descendant(
      of: find.byKey(const ValueKey('node_0_root')),
      matching: find.byType(TextField)
    ).first);
    expect(projectInputAfterSpace.controller?.text, "Slow ");

    const fullTitle = "Slow Project A";
    for (int i = part1.length; i < fullTitle.length; i++) {
      final textSoFar = fullTitle.substring(0, i + 1);
      await tester.enterText(projectInput, textSoFar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
    }
    await tester.pumpAndSettle();

    // Verify only 1 root node
    expect(nodeService.rootNodes.length, 1);
    // Verify only 1 file
    final projectFiles = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md')).toList();
    expect(projectFiles.length, 1);
    expect(projectFiles.first.readAsStringSync(), contains("# $fullTitle"));

    // --- 2. Slow Type Task ---
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 1100));

    final taskInput = find.descendant(
      of: find.byKey(ValueKey('node_1_${container.read(selectionProvider).selectedProjectId}')),
      matching: find.byType(TextField)
    ).first;

    const taskPart1 = "Slow";
    for (int i = 0; i < taskPart1.length; i++) {
      await tester.enterText(taskInput, taskPart1.substring(0, i + 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(nodeService.rootNodes.first.children.length, 1, reason: "Space key should not create new task while editing");

    const taskFullTitle = "Slow Task A";
    for (int i = taskPart1.length; i < taskFullTitle.length; i++) {
      final textSoFar = taskFullTitle.substring(0, i + 1);
      await tester.enterText(taskInput, textSoFar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
    }
    await tester.pumpAndSettle();

    // Verify still only 1 child
    expect(nodeService.rootNodes.first.children.length, 1);
    expect(projectFiles.first.readAsStringSync(), contains("- [ ] $taskFullTitle"));

    // --- 3. Slow Type Subtask ---
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 1100));

    final subtaskInput = find.descendant(
      of: find.byKey(ValueKey('node_2_${container.read(selectionProvider).selectedTaskId}')),
      matching: find.byType(TextField)
    ).first;

    const subPart1 = "Slow";
    for (int i = 0; i < subPart1.length; i++) {
      await tester.enterText(subtaskInput, subPart1.substring(0, i + 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(nodeService.rootNodes.first.children.first.children.length, 1, reason: "Space key should not create new subtask while editing");

    const subFullTitle = "Slow Subtask A";
    for (int i = subPart1.length; i < subFullTitle.length; i++) {
      final textSoFar = subFullTitle.substring(0, i + 1);
      await tester.enterText(subtaskInput, textSoFar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
    }
    await tester.pumpAndSettle();

    // Verify still only 1 grandchild
    expect(nodeService.rootNodes.first.children.first.children.length, 1);
    expect(projectFiles.first.readAsStringSync(), contains("- [ ] $subFullTitle"));
  });
}
