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

  void fireWatcher() {
    final todosDir = Directory('$testBaseDir/todos');
    final nodes = <Node>[];
    if (todosDir.existsSync()) {
      final files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
      for (final file in files) {
        nodes.add(MarkdownParser.parseNode(file.readAsStringSync()));
      }
    }
    _controller.add(nodes);
  }

  @override
  Future<void> saveNode(Node node) async {
    final category = 'unsorted';
    final fileName = node.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
    final filePath = '$testBaseDir/todos/$category/$fileName.md';

    final file = File(filePath);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    file.writeAsStringSync(MarkdownParser.nodeToMarkdown(node));
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    final todosDir = Directory('$testBaseDir/todos');
    if (todosDir.existsSync()) {
       final files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
       for (final f in files) {
          if (MarkdownParser.parseNode(f.readAsStringSync()).id == nodeId) {
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
    await tester.pump(const Duration(milliseconds: 500));

    // Stop Editing first (since we disabled Delete while editing)
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 200));

    // 3. Delete Project (Cmd + Backspace)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();

    // Verify Gone from UI immediately
    expect(find.text("Ghost Project"), findsNothing, reason: "Project should be removed immediately from UI");

    // 4. Advance time to let Debounce Timer fire (if not cancelled)
    await tester.pump(const Duration(milliseconds: 1500));

    // Debug: Check if file exists
    final todosDir = Directory('${tempDir.path}/todos');
    final count = todosDir.listSync(recursive: true).whereType<File>().length;
    print("Debug: Files found after wait: $count");

    // 5. Trigger Watcher to simulate file system detecting the 'new' file
    fileService.fireWatcher();
    await tester.pumpAndSettle();

    // 6. Assert
    expect(find.text("Ghost Project"), findsNothing, reason: "Project should NOT reappear due to pending debounce timer");
  });
}
