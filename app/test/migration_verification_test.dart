import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/file_system_service.dart';
import 'package:flutter_app/models/node.dart';
import 'package:path/path.dart' as path;

void main() {
  group('FileSystemService Migration', () {
    late Directory tempDir;
    late FileSystemService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ai_migration_test');
      service = FileSystemService(baseDir: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Saves node to Markdown file', () async {
      final node = Node(
        id: 'p1',
        title: 'Test Project',
        children: [
          Node(id: 'new_task', title: 'New Task Created', parentId: 'p1'),
        ],
      );

      await service.saveNode(node);

      final projectDir = Directory(path.join(tempDir.path, 'todos', 'unsorted'));
      expect(await projectDir.exists(), isTrue);

      final files = projectDir.listSync();

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
