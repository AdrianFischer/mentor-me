import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/utils/markdown_parser.dart';

void main() {
  group('MarkdownParser', () {
    test('parseProject should correctly parse a standard markdown file', () {
      final markdown = '''
---
id: project-123
tags: [work, urgent]
version: 1
---

# My Project

This is a description.

- [ ] Task 1
- [x] Task 2
''';

      final project = MarkdownParser.parseProject(markdown);

      expect(project.id, 'project-123');
      expect(project.title, 'My Project');
      expect(project.tags, containsAll(['work', 'urgent']));
      expect(project.notes?.trim(), 'This is a description.');
      expect(project.tasks.length, 2);
      expect(project.tasks[0].title, 'Task 1');
      expect(project.tasks[0].isCompleted, false);
      expect(project.tasks[1].title, 'Task 2');
      expect(project.tasks[1].isCompleted, true);
    });

    test('toMarkdown should correctly serialize a Project', () {
      final project = Project(
        id: 'project-456',
        title: 'Serialized Project',
        tags: ['personal'],
        notes: 'Some notes.',
        tasks: [
          Task(id: 't1', title: 'Task A', isCompleted: false),
        ],
      );

      final markdown = MarkdownParser.toMarkdown(project);

      expect(markdown, contains('id: project-456'));
      expect(markdown, contains('tags: [personal]'));
      expect(markdown, contains('# Serialized Project'));
      expect(markdown, contains('Some notes.'));
      expect(markdown, contains('- [ ] Task A'));
    });
  });
}
