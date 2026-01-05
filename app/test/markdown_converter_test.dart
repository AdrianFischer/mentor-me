import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/services/markdown_converter.dart';

void main() {
  group('MarkdownConverter Tests', () {
    final converter = MarkdownConverter();

    test('Converts Project to Markdown', () {
      final project = Project(
        id: 'p1',
        title: 'Project Alpha',
        tags: ['urgent', 'work'],
        notes: 'Top secret project.',
        tasks: [
          Task(
            id: 't1',
            title: 'Task 1',
            isCompleted: false,
            tags: ['dev'],
            subtasks: [
              Subtask(id: 's1', title: 'Subtask 1.1', isCompleted: true),
              Subtask(id: 's2', title: 'Subtask 1.2', isCompleted: false),
            ],
            notes: 'Task 1 notes.',
          ),
          Task(
            id: 't2',
            title: 'Task 2',
            isCompleted: true,
          ),
        ],
      );

      final markdown = converter.projectToMarkdown(project);

      expect(markdown, contains('# Project Alpha'));
      expect(markdown, contains('#urgent #work'));
      expect(markdown, contains('Top secret project.'));
      expect(markdown, contains('- [ ] Task 1 #dev'));
      expect(markdown, contains('  - [x] Subtask 1.1'));
      expect(markdown, contains('  - [ ] Subtask 1.2'));
      expect(markdown, contains('  Task 1 notes.'));
      expect(markdown, contains('- [x] Task 2'));
    });

    test('Parses Markdown to Project', () {
      const markdown = '''# Project Beta
#personal #home
Notes for Beta.

- [ ] Task X #code
  - [ ] Subtask X.1
  - [x] Subtask X.2
  Notes for Task X.
- [x] Task Y
''';

      final project = converter.markdownToProject(markdown, id: 'p_beta');

      expect(project.title, 'Project Beta');
      expect(project.tags, containsAll(['personal', 'home']));
      expect(project.notes, contains('Notes for Beta.'));
      expect(project.tasks.length, 2);
      
      final taskX = project.tasks.firstWhere((t) => t.title.contains('Task X'));
      expect(taskX.isCompleted, false);
      expect(taskX.tags, contains('code'));
      expect(taskX.notes, contains('Notes for Task X.'));
      expect(taskX.subtasks.length, 2);
      expect(taskX.subtasks[0].title, 'Subtask X.1');
      expect(taskX.subtasks[0].isCompleted, false);
      expect(taskX.subtasks[1].isCompleted, true);

      final taskY = project.tasks.firstWhere((t) => t.title.contains('Task Y'));
      expect(taskY.isCompleted, true);
    });
  });
}
