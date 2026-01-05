import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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
      
      service = MarkdownPersistenceService(baseDir: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Saves new task as file', () async {
      final newTask = Task(id: 'new_task', title: 'New Task Created');
      final project = Project(id: 'p1', title: 'Test Project');
      
      await service.saveTask(newTask, project);

      final todoDir = Directory(path.join(tempDir.path, 'to_dos'));
      final files = todoDir.listSync();
      
      // Find the file ending with _new_task_created.md (slugified title)
      // Slug for "New Task Created" -> "new_task_created"
      final taskFile = files.whereType<File>().firstWhere(
        (f) => f.path.contains('new_task_created.md'),
        orElse: () => throw Exception("Task file not found"),
      );
      
      final content = await taskFile.readAsString();
      expect(content, contains('New Task Created'));
      expect(content, contains('State: Pending'));
    });
  });
}