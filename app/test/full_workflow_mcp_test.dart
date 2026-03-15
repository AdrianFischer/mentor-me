import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/services/file_system_service.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/utils/markdown_parser.dart';
import 'package:mocktail/mocktail.dart';

// MCP Tool Imports
import 'package:flutter_app/ai_tools/ai_tool.dart';
import 'package:flutter_app/ai_tools/implementations/add_project_tool.dart';
import 'package:flutter_app/ai_tools/implementations/add_task_tool.dart';
import 'package:flutter_app/ai_tools/implementations/add_subtask_tool.dart';
import 'package:flutter_app/ai_tools/implementations/update_notes_tool.dart';
import 'package:flutter_app/ai_tools/implementations/update_item_name_tool.dart';
import 'package:flutter_app/ai_tools/implementations/delete_item_tool.dart';

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
      nodes.add(MarkdownParser.parseNode(content));
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
          // ignore error
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
    tempDir = await Directory.systemTemp.createTemp('gemini_mcp_test_');
    fileService = TestFileSystemService(testBaseDir: tempDir.path);
  });

  tearDown(() async {
    fileService.dispose();
    await tempDir.delete(recursive: true);
  });

  testWidgets('MCP Workflow: Create, Edit, Delete, Verify persistence', timeout: const Timeout(Duration(seconds: 120)), (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        fileSystemServiceProvider.overrideWithValue(fileService),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    // Allow async init
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));
    final nodeService = container.read(nodeServiceProvider);
    final dataService = container.read(dataServiceProvider);
    final toolContext = ToolContext(nodeService, dataService);

    // 1) Verify no nodes initially
    expect(nodeService.rootNodes.isEmpty, isTrue);
    final todosDir = Directory('${tempDir.path}/todos');
    if (todosDir.existsSync()) {
       expect(todosDir.listSync(recursive: true).where((e) => e.path.endsWith('.md')).isEmpty, isTrue);
    }

    // 2) MCP: Create Project "My new Project"
    final addProjectTool = AddProjectTool();
    final createResult = await addProjectTool.execute({'title': 'My new Project'}, toolContext);
    final projectId = createResult['project_id'] as String;

    // Verify In-Memory
    expect(nodeService.rootNodes.length, 1);
    expect(nodeService.rootNodes.first.title, 'My new Project');
    expect(nodeService.rootNodes.first.id, projectId);

    // Verify Persistence (Debounce wait)
    await tester.pump(const Duration(milliseconds: 1100));
    var files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
    expect(files.length, 1);
    expect(files.first.readAsStringSync(), contains("# My new Project"));

    // 3) MCP: Add Notes to Project "my new notes"
    final updateNotesTool = UpdateNotesTool();
    await updateNotesTool.execute({'item_id': projectId, 'notes': 'my new notes'}, toolContext);

    expect(nodeService.findNode(projectId)!.notes, 'my new notes');

    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), contains("my new notes"));

    // 4) MCP: Add Task "My new Task"
    final addTaskTool = AddTaskTool();
    final taskResult = await addTaskTool.execute({'project_id': projectId, 'title': 'My new Task'}, toolContext);
    final taskId = taskResult['task_id'] as String;

    expect(nodeService.rootNodes.first.children.length, 1);
    expect(nodeService.rootNodes.first.children.first.title, 'My new Task');

    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), contains("- [ ] My new Task"));

    // 5) MCP: Add Notes to Task "Task notes content"
    await updateNotesTool.execute({'item_id': taskId, 'notes': 'Task notes content'}, toolContext);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), contains("Task notes content"));

    // 6) MCP: Add Subtask "My new Subtask"
    final addSubtaskTool = AddSubtaskTool();
    final subtaskResult = await addSubtaskTool.execute({'task_id': taskId, 'title': 'My new Subtask'}, toolContext);
    final subtaskId = subtaskResult['subtask_id'] as String;

    expect(nodeService.findNode(taskId)!.children.length, 1);
    expect(nodeService.findNode(taskId)!.children.first.title, 'My new Subtask');

    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), contains("- [ ] My new Subtask"));

    // 7) MCP: Add Notes to Subtask "Subtask notes content"
    await updateNotesTool.execute({'item_id': subtaskId, 'notes': 'Subtask notes content'}, toolContext);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), contains("Subtask notes content"));

    // 8) MCP: Update Subtask Title
    final updateNameTool = UpdateItemNameTool();
    await updateNameTool.execute({'item_id': subtaskId, 'new_name': 'Renamed Subtask'}, toolContext);

    expect(nodeService.findNode(subtaskId)!.title, 'Renamed Subtask');
    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), contains("- [ ] Renamed Subtask"));

    // 9) External Update Verification
    var content = files.first.readAsStringSync();
    var newContent = content.replaceFirst("Renamed Subtask", "Renamed Subtask (External)");
    files.first.writeAsStringSync(newContent);

    await tester.runAsync(() async {
      fileService.reloadFromDisk();
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(nodeService.findNode(subtaskId)?.title ?? nodeService.rootNodes.first.children.first.children.first.title, 'Renamed Subtask (External)');

    // 10) MCP: Delete Subtask
    final deleteTool = DeleteItemTool();
    await deleteTool.execute({'item_id': subtaskId}, toolContext);

    expect(nodeService.findNode(taskId)!.children.isEmpty, isTrue);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), isNot(contains("Renamed Subtask (External)")));

    // 11) MCP: Delete Task
    await deleteTool.execute({'item_id': taskId}, toolContext);

    expect(nodeService.rootNodes.first.children.isEmpty, isTrue);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(files.first.readAsStringSync(), isNot(contains("My new Task")));

    // 12) MCP: Delete Project
    await deleteTool.execute({'item_id': projectId}, toolContext);

    expect(nodeService.rootNodes.isEmpty, isTrue);
    await tester.pump(const Duration(milliseconds: 1100));

    files = todosDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
  });
}
