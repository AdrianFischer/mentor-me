import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/utils/markdown_parser.dart';

void main() {
  group('MarkdownParser.parseNode', () {
    test('parses basic node with children', () {
      final md = '''---
id: proj-1
tags: ["#work"]
---

# My Project

Project notes here.

- [ ] Task 1 <!-- id: t1 -->
  Task 1 notes
  - [x] Subtask 1.1 <!-- id: s1 -->
    Subtask notes
  - [ ] Subtask 1.2 <!-- id: s2 -->
- [x] Task 2 <!-- id: t2 -->
''';

      final node = MarkdownParser.parseNode(md);

      expect(node.id, 'proj-1');
      expect(node.title, 'My Project');
      expect(node.tags, ['#work']);
      expect(node.notes, 'Project notes here.');
      expect(node.children.length, 2);

      final t1 = node.children[0];
      expect(t1.id, 't1');
      expect(t1.title, 'Task 1');
      expect(t1.isCompleted, false);
      expect(t1.notes, 'Task 1 notes');
      expect(t1.parentId, 'proj-1');
      expect(t1.children.length, 2);

      expect(t1.children[0].id, 's1');
      expect(t1.children[0].isCompleted, true);
      expect(t1.children[0].notes, 'Subtask notes');
      expect(t1.children[0].parentId, 't1');

      expect(t1.children[1].id, 's2');

      final t2 = node.children[1];
      expect(t2.id, 't2');
      expect(t2.isCompleted, true);
    });

    test('parses 4 levels deep', () {
      final md = '''---
id: root
---

# Deep Tree

- [ ] Level 1 <!-- id: l1 -->
  - [ ] Level 2 <!-- id: l2 -->
    - [ ] Level 3 <!-- id: l3 -->
      - [ ] Level 4 <!-- id: l4 -->
''';

      final node = MarkdownParser.parseNode(md);

      expect(node.children.length, 1);
      final l1 = node.children[0];
      expect(l1.id, 'l1');
      expect(l1.children.length, 1);

      final l2 = l1.children[0];
      expect(l2.id, 'l2');
      expect(l2.parentId, 'l1');
      expect(l2.children.length, 1);

      final l3 = l2.children[0];
      expect(l3.id, 'l3');
      expect(l3.parentId, 'l2');
      expect(l3.children.length, 1);

      final l4 = l3.children[0];
      expect(l4.id, 'l4');
      expect(l4.parentId, 'l3');
      expect(l4.children, isEmpty);
    });

    test('generates IDs when missing', () {
      final md = '''---
id: root
---

# Test

- [ ] No ID task
  - [ ] No ID subtask
''';

      final node = MarkdownParser.parseNode(md);
      expect(node.children.length, 1);
      expect(node.children[0].id, isNotEmpty);
      expect(node.children[0].children[0].id, isNotEmpty);
    });
  });

  group('MarkdownParser.nodeToMarkdown', () {
    test('round-trip preserves structure', () {
      final md = '''---
id: proj-1
tags: ["#work", "#urgent"]
---

# My Project

Some notes.

- [ ] Task A <!-- id: ta -->
  Task A notes
  - [x] Sub A1 <!-- id: sa1 -->
    Sub notes
  - [ ] Sub A2 <!-- id: sa2 -->

- [x] Task B <!-- id: tb -->
''';

      final node = MarkdownParser.parseNode(md);
      final output = MarkdownParser.nodeToMarkdown(node);
      final reparsed = MarkdownParser.parseNode(output);

      expect(reparsed.id, 'proj-1');
      expect(reparsed.title, 'My Project');
      expect(reparsed.notes, 'Some notes.');
      expect(reparsed.tags, ['#work', '#urgent']);
      expect(reparsed.children.length, 2);

      expect(reparsed.children[0].id, 'ta');
      expect(reparsed.children[0].title, 'Task A');
      expect(reparsed.children[0].notes, 'Task A notes');
      expect(reparsed.children[0].children.length, 2);
      expect(reparsed.children[0].children[0].id, 'sa1');
      expect(reparsed.children[0].children[0].isCompleted, true);
      expect(reparsed.children[0].children[0].notes, 'Sub notes');
      expect(reparsed.children[0].children[1].id, 'sa2');

      expect(reparsed.children[1].id, 'tb');
      expect(reparsed.children[1].isCompleted, true);
    });

    test('deep nesting round-trip', () {
      final md = '''---
id: deep
---

# Deep

- [ ] A <!-- id: a -->
  - [ ] B <!-- id: b -->
    - [ ] C <!-- id: c -->
      - [ ] D <!-- id: d -->
''';

      final node = MarkdownParser.parseNode(md);
      final output = MarkdownParser.nodeToMarkdown(node);
      final reparsed = MarkdownParser.parseNode(output);

      expect(reparsed.children[0].id, 'a');
      expect(reparsed.children[0].children[0].id, 'b');
      expect(reparsed.children[0].children[0].children[0].id, 'c');
      expect(reparsed.children[0].children[0].children[0].children[0].id, 'd');
    });
  });

  group('backward compatibility', () {
    test('parseNode handles 2-level structure correctly', () {
      final md = '''---
id: compat
tags: ["#test"]
---

# Compat Test

Notes.

- [ ] Task 1 <!-- id: t1 -->
  Task note
  - [x] Sub 1 <!-- id: s1 -->
- [x] Task 2 <!-- id: t2 -->
''';

      final node = MarkdownParser.parseNode(md);

      expect(node.id, 'compat');
      expect(node.title, 'Compat Test');
      expect(node.children.length, 2);
      expect(node.children[0].id, 't1');
      expect(node.children[0].title, 'Task 1');
      expect(node.children[0].children.length, 1);
      expect(node.children[0].children[0].id, 's1');
      expect(node.children[1].id, 't2');
      expect(node.children[1].isCompleted, true);
    });
  });

  group('Markdown Node Parser Edge Cases', () {
    test('handles malformed frontmatter gracefully', () {
      final md = '''---
id: [invalid yaml
tags: unclosed string"
---

# Malformed Test

- [ ] Task 1 <!-- id: t1 -->
''';
      final node = MarkdownParser.parseNode(md);
      expect(node.id, isNotEmpty);
      expect(node.title, 'Malformed Test');
      expect(node.children.length, 1);
      expect(node.children[0].id, 't1');
    });

    test('handles missing delimiters gracefully', () {
      final md = '''# No Delimiters Test

Just some notes without frontmatter.

- [ ] Task 1 <!-- id: t1 -->
''';
      final node = MarkdownParser.parseNode(md);
      expect(node.id, isNotEmpty);
      expect(node.title, 'No Delimiters Test');
      expect(node.notes, 'Just some notes without frontmatter.');
      expect(node.children.length, 1);
      expect(node.children[0].id, 't1');
    });

    test('handles deeply nested unclosed lists or jumped indentation', () {
      final md = '''---
id: edge-nested
---

# Nested Edge Cases

- [ ] Level 1 <!-- id: l1 -->
        - [ ] Jumped Level <!-- id: jl -->
  - [ ] Normal Level 2 <!-- id: nl2 -->
''';
      final node = MarkdownParser.parseNode(md);
      expect(node.title, 'Nested Edge Cases');
      expect(node.children.length, 1);
      expect(node.children[0].id, 'l1');
      expect(node.children[0].children.isNotEmpty, true);
    });
  });
}
