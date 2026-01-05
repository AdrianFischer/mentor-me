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
      service = MarkdownPersistenceService(baseDir: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Saves project to Markdown file', () async {
      final newTask = Task(id: 'new_task', title: 'New Task Created');
      final project = Project(id: 'p1', title: 'Test Project', tasks: [newTask]);
      
      await service.saveProject(project);
      
      final projectDir = Directory(path.join(tempDir.path, 'todos', 'unsorted'));
      expect(await projectDir.exists(), isTrue);
      
      final files = projectDir.listSync();
      
      // Slug for "Test Project" -> "test_project"
      final projectFile = files.whereType<File>().firstWhere(
        (f) => f.path.contains('test_project.md'),
        orElse: () => throw Exception("Project file not found"),
      );
      
      final content = await projectFile.readAsString();
      expect(content, contains('# Test Project'));
      expect(content, contains('- [ ] New Task Created'));
    });
  });
}
