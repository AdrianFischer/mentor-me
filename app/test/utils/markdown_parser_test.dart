import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/utils/markdown_parser.dart';
import 'package:flutter_app/models/node.dart';

void main() {
  group('MarkdownParser.parseNode', () {
    test('parseNode should correctly parse a standard markdown file', () {
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

      final node = MarkdownParser.parseNode(markdown);

      expect(node.id, 'project-123');
      expect(node.title, 'My Project');
      expect(node.tags, containsAll(['work', 'urgent']));
      expect(node.notes?.trim(), 'This is a description.');
      expect(node.children.length, 2);
      expect(node.children[0].title, 'Task 1');
      expect(node.children[0].isCompleted, false);
      expect(node.children[1].title, 'Task 2');
      expect(node.children[1].isCompleted, true);
    });

    test('nodeToMarkdown should correctly serialize a Node', () {
      final node = Node(
        id: 'project-456',
        title: 'Serialized Project',
        tags: ['personal'],
        notes: 'Some notes.',
        children: [
          Node(id: 't1', title: 'Task A', isCompleted: false, parentId: 'project-456'),
        ],
      );

      final markdown = MarkdownParser.nodeToMarkdown(node);

      expect(markdown, contains('id: project-456'));
      expect(markdown, contains('# Serialized Project'));
      expect(markdown, contains('Some notes.'));
      expect(markdown, contains('- [ ] Task A'));
    });

    test('parseNode should handle empty file', () {
      final node = MarkdownParser.parseNode('');
      expect(node.title, 'Untitled');
      expect(node.children, isEmpty);
    });

    test('parseNode should handle missing frontmatter', () {
      final markdown = '# Just a Title\n\nSome notes.';
      final node = MarkdownParser.parseNode(markdown);
      expect(node.title, 'Just a Title');
      expect(node.notes, 'Some notes.');
      expect(node.id, isNotEmpty);
    });

    test('parseNode should handle malformed frontmatter gracefully', () {
      final markdown = '''
---
id: [invalid
tags: {
---

# Title
''';
      final node = MarkdownParser.parseNode(markdown);
      expect(node.title, 'Title');
      expect(node.id, isNotEmpty);
    });
  });
}
