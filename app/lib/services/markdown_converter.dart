import '../models/models.dart';
import 'package:uuid/uuid.dart';

class MarkdownConverter {
  final _uuid = const Uuid();

  String projectToMarkdown(Project project) {
    final buffer = StringBuffer();
    buffer.writeln('# ${project.title}');
    buffer.writeln('<!-- id: ${project.id} -->');
    
    if (project.tags.isNotEmpty) {
      buffer.writeln(project.tags.map((t) => '#$t').join(' '));
    }
    
    if (project.notes != null && project.notes!.isNotEmpty) {
      buffer.writeln(project.notes);
    }
    
    buffer.writeln();

    for (final task in project.tasks) {
      final status = task.isCompleted ? 'x' : ' ';
      final taskTags = task.tags.isNotEmpty ? ' ' + task.tags.map((t) => '#$t').join(' ') : '';
      buffer.writeln('- [$status] ${task.title}$taskTags');
      
      if (task.notes != null && task.notes!.isNotEmpty) {
        // Indent notes to associate with task? 
        // For simplicity, let's just put them on the next line.
        // If we indent them, they might be seen as sub-items.
        // Standard markdown often puts notes as a block following the item.
        buffer.writeln('  ${task.notes}');
      }
      
      for (final subtask in task.subtasks) {
        final subStatus = subtask.isCompleted ? 'x' : ' ';
        final subTags = subtask.tags.isNotEmpty ? ' ' + subtask.tags.map((t) => '#$t').join(' ') : '';
        buffer.writeln('  - [$subStatus] ${subtask.title}$subTags');
        if (subtask.notes != null && subtask.notes!.isNotEmpty) {
          buffer.writeln('    ${subtask.notes}');
        }
      }
      buffer.writeln(); // Blank line between tasks
    }

    return buffer.toString().trim() + '\n';
  }

  Project markdownToProject(String markdown, {String? id}) {
    final lines = markdown.split('\n');
    String title = 'Untitled Project';
    String? extractedId;
    List<String> tags = [];
    StringBuffer notesBuffer = StringBuffer();
    List<Task> tasks = [];
    
    Task? currentTask;
    StringBuffer? currentTaskNotes;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('# ')) {
        title = trimmed.substring(2).trim();
      } else if (trimmed.startsWith('<!-- id:') && trimmed.endsWith('-->')) {
        extractedId = trimmed.substring(8, trimmed.length - 3).trim();
      } else if (trimmed.startsWith('#') && !trimmed.contains('[') && currentTask == null) {
        // Project tags
        tags.addAll(_extractTags(trimmed));
      } else if (trimmed.startsWith('- [') || trimmed.startsWith('  - [')) {
        // It's a task or subtask
        final isSubtask = line.startsWith('  ') || line.startsWith('	');
        final isCompleted = trimmed.contains('[x]');
        
        // Extract title and tags
        // format: - [ ] Title #tag1 #tag2
        final content = trimmed.substring(trimmed.indexOf(']') + 1).trim();
        final taskTags = _extractTags(content);
        final taskTitle = _cleanTitle(content);

        if (isSubtask && currentTask != null) {
          final subtask = Subtask(
            id: _uuid.v4(),
            title: taskTitle,
            isCompleted: isCompleted,
            tags: taskTags,
          );
          currentTask = currentTask.copyWith(subtasks: [...currentTask.subtasks, subtask]);
        } else {
          // Finish previous task notes
          if (currentTask != null) {
            tasks.add(currentTask.copyWith(notes: currentTaskNotes?.toString().trim()));
          }
          
          currentTask = Task(
            id: _uuid.v4(),
            title: taskTitle,
            isCompleted: isCompleted,
            tags: taskTags,
          );
          currentTaskNotes = StringBuffer();
        }
      } else {
        // It's a note
        if (currentTask != null) {
          currentTaskNotes?.writeln(trimmed);
        } else if (tasks.isEmpty) {
          notesBuffer.writeln(trimmed);
        }
      }
    }
    
    if (currentTask != null) {
      tasks.add(currentTask.copyWith(notes: currentTaskNotes?.toString().trim()));
    }

    return Project(
      id: id ?? extractedId ?? _uuid.v4(),
      title: title,
      tags: tags,
      notes: notesBuffer.toString().trim(),
      tasks: tasks,
    );
  }

  List<String> _extractTags(String text) {
    final regex = RegExp(r'#([\w\u00C0-\u017F-]+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }

  String _cleanTitle(String text) {
    // Remove tags from title
    return text.replaceAll(RegExp(r'#[\w\u00C0-\u017F-]+'), '').trim();
  }
}
