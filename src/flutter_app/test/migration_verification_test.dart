import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/models/models.dart';
import 'package:path/path.dart' as path;

void main() {
  group('MarkdownPersistenceService Migration', () {
    late Directory tempDir;
    late MarkdownPersistenceService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ai_migration_test');
      final todoDir = Directory(path.join(tempDir.path, 'to_dos'));
      await todoDir.create();
      
      // Mock .env
      dotenv.testLoad(mergeWith: {'DATA_DIR': tempDir.path});
      
      service = MarkdownPersistenceService();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Loads existing tasks from to_dos folder', () async {
      // Create a mock task file
      final file = File(path.join(tempDir.path, 'to_dos', '2025_12_16_1000_mock_task.md'));
      await file.writeAsString('''
Mock Task Description
mock_task_id
Summary
State: In Progress
Focus: Testing

Log Book
Entry 1
''');

      await service.init();
      final tasks = await service.loadTasks();

      expect(tasks.length, 1);
      expect(tasks.first.id, 'mock_task_id');
      expect(tasks.first.title, 'Mock Task Description');
      expect(tasks.first.isCompleted, false);
    });

    test('Saves new task as file', () async {
      await service.init();
      final newTask = Task(id: 'new_task', title: 'New Task Created');
      
      await service.saveTask(newTask);

      final todoDir = Directory(path.join(tempDir.path, 'to_dos'));
      final files = todoDir.listSync();
      
      // Find the file ending with _new_task.md
      final taskFile = files.whereType<File>().firstWhere(
        (f) => f.path.endsWith('_new_task.md') || f.path.endsWith('new_task.md'),
        orElse: () => throw Exception("Task file not found"),
      );
      
      final content = await taskFile.readAsString();
      expect(content, contains('New Task Created'));
      expect(content, contains('new_task'));
      expect(content, contains('State: In Progress'));
    });
    
    test('Updates existing task file', () async {
       // Create initial
      final file = File(path.join(tempDir.path, 'to_dos', '2025_12_16_1000_update_test.md'));
      await file.writeAsString('''
Old Title
update_test
Summary
State: In Progress
Focus: None

Log Book
''');
      
      await service.init();
      final task = Task(id: 'update_test', title: 'New Title', isCompleted: true);
      
      await service.saveTask(task);
      
      final content = await file.readAsString();
      expect(content, contains('New Title')); // Line 1 updated
      expect(content, contains('State: Completed')); // Status updated
      expect(content, contains('update_test')); // ID Preserved
    });
  });
}



