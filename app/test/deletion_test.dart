import 'dart:async';
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
  final StreamController<List<Project>> _controller = StreamController<List<Project>>.broadcast();
  
  TestFileSystemService({required this.testBaseDir}) : super(baseDir: testBaseDir);

  @override
  Stream<List<Project>> watchProjects() {
    return _controller.stream;
  }

  void fireWatcher() {
    // Reloads all files to simulate watcher event
    final todosDir = Directory('$testBaseDir/todos');
    final projects = <Project>[];
    if (todosDir.existsSync()) {
      final files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
      for (final file in files) {
        projects.add(MarkdownParser.parseProject(file.readAsStringSync()));
      }
    }
    _controller.add(projects);
  }

  @override
  Future<void> saveProject(Project project) async {
    final category = 'unsorted';
    final fileName = project.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
    final filePath = '$testBaseDir/todos/$category/$fileName.md';
    
    final file = File(filePath);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    file.writeAsStringSync(MarkdownParser.toMarkdown(project));
  }

  @override
  Future<void> deleteProject(String projectId) async {
    // In a real app, we'd delete the file.
    // For reproduction, we assume the bug is that saveProject is called AFTER deleteProject.
    // So we need to delete it here.
    
    // Naive implementation: find file by content ID or just assume we know the path logic?
    // Since saveProject uses title-based name, changing title changes name.
    // For this test, we can just look for files.
    final todosDir = Directory('$testBaseDir/todos');
    if (todosDir.existsSync()) {
       final files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
       for (final f in files) {
          if (MarkdownParser.parseProject(f.readAsStringSync()).id == projectId) {
             f.deleteSync();
          }
       }
    }
  }
}

void main() {
  late Directory tempDir;
  late TestFileSystemService fileService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gemini_del_test_');
    fileService = TestFileSystemService(testBaseDir: tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  testWidgets('Delete Project after Edit (Debounce Race Condition)', (WidgetTester tester) async {
    // Setup
    await tester.pumpWidget(ProviderScope(
      overrides: [
        fileSystemServiceProvider.overrideWithValue(fileService),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    // 1. Create Project
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump(const Duration(milliseconds: 500));
    
    await tester.enterText(find.byType(TextField).first, "Ghost Project");
    await tester.pump();
    
    // 2. Trigger Debounce (Type more)
    // The previous enterText triggered updateTitle which starts 1s timer.
    // We wait 500ms (less than 1s).
    await tester.pump(const Duration(milliseconds: 500));
    
    // Stop Editing first (since we disabled Delete while editing)
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 200));

    // 3. Delete Project (Cmd + Backspace)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump(); // Process deletion in UI
    
    // Verify Gone from UI immediately
    expect(find.text("Ghost Project"), findsNothing, reason: "Project should be removed immediately from UI");
    
    // 4. Advance time to let Debounce Timer fire (if not cancelled)
    await tester.pump(const Duration(milliseconds: 1500));
    
    // Debug: Check if file exists
    final todosDir = Directory('${tempDir.path}/todos');
    final count = todosDir.listSync(recursive: true).whereType<File>().length;
    print("Debug: Files found after wait: $count");

    // 5. Trigger Watcher to simulate file system detecting the 'new' file
    // (In real app, file change triggers watcher).
    fileService.fireWatcher();
    await tester.pumpAndSettle();
    
    // 6. Assert
    // If fixed: Project should still be gone.
    // If bug: Project reappears.
    expect(find.text("Ghost Project"), findsNothing, reason: "Project should NOT reappear due to pending debounce timer");
  });
}