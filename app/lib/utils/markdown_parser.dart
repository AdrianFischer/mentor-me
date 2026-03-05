import 'package:yaml/yaml.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class _MutableSubtask {
  String id;
  String title;
  bool isCompleted;
  String? notes;
  
  _MutableSubtask(this.id, this.title, this.isCompleted);

  Subtask toSubtask() {
    return Subtask(id: id, title: title, isCompleted: isCompleted, notes: notes?.trim());
  }
}

class _MutableTask {
  String id;
  String title;
  bool isCompleted;
  String? notes;
  List<_MutableSubtask> subtasks = [];

  _MutableTask(this.id, this.title, this.isCompleted);

  Task toTask(String projectId) {
    return Task(
      id: id, 
      title: title, 
      isCompleted: isCompleted, 
      projectId: projectId,
      notes: notes?.trim(),
      subtasks: subtasks.map((s) => s.toSubtask()).toList(),
    );
  }
}

class MarkdownParser {
  static const _uuid = Uuid();
  static final _idRegex = RegExp(r'<!-- id: ([a-zA-Z0-9-]+) -->$');

  static Project parseProject(String content) {
    // 1. Split Frontmatter
    final parts = content.split('---');
    Map<String, dynamic> frontmatter = {};
    String body = content;

    // A simple check for frontmatter at the start of the file
    if (content.trimLeft().startsWith('---') && parts.length >= 3) {
      final yamlStr = parts[1];
      try {
        final yaml = loadYaml(yamlStr);
        if (yaml is Map) {
          // Convert YamlMap to standard Map
          frontmatter = Map<String, dynamic>.from(yaml);
        }
      } catch (e) {
        print('Error parsing YAML: $e');
      }
      // Re-join the rest in case "---" appears in the body
      body = parts.sublist(2).join('---').trim();
    }

    // 2. Parse Body (Title, Notes, Tasks)
    String title = 'Untitled';
    List<_MutableTask> mutableTasks = [];
    StringBuffer projectNotesBuffer = StringBuffer();
    
    _MutableTask? currentTask;
    _MutableSubtask? currentSubtask;
    bool titleFound = false;

    final lines = body.split('\n');

    for (var line in lines) {
      // Don't trim yet, we need indentation
      if (!titleFound && line.trim().isEmpty) continue;

      if (!titleFound && line.trim().startsWith('# ')) {
        title = line.trim().substring(2).trim();
        titleFound = true;
        continue;
      }

      // Check for Task
      final trimmed = line.trim();
      final isTaskLine = trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ');

      if (isTaskLine) {
        final isCompleted = trimmed.startsWith('- [x] ');
        var rawTitle = trimmed.substring(6).trim();
        
        // Extract ID if present
        String id = _uuid.v4();
        final match = _idRegex.firstMatch(rawTitle);
        if (match != null) {
          id = match.group(1)!;
          rawTitle = rawTitle.substring(0, match.start).trim();
        }
        
        // Determine level based on indentation
        // Assuming 2 spaces for indentation
        final indentLevel = line.indexOf('-');
        
        if (indentLevel >= 2 && currentTask != null) {
          // It is a subtask
          final subtask = _MutableSubtask(id, rawTitle, isCompleted);
          currentTask.subtasks.add(subtask);
          currentSubtask = subtask;
        } else {
          // It is a root task
          final task = _MutableTask(id, rawTitle, isCompleted);
          mutableTasks.add(task);
          currentTask = task;
          currentSubtask = null;
        }
      } else {
        // It is Content/Notes or Empty Line
        if (titleFound) {
           // Heuristic: If it's indented, it belongs to current item.
           // However, blank lines might be tricky.
           
           if (currentSubtask != null && (line.startsWith('    ') || line.trim().isEmpty)) {
             // Subtask Note (4 spaces)
             if (currentSubtask.notes == null) currentSubtask.notes = "";
             currentSubtask.notes = (currentSubtask.notes! + "\n" + line.trim()).trim();
           } else if (currentTask != null && (line.startsWith('  ') || line.trim().isEmpty)) {
             // Task Note (2 spaces)
             // But wait, if we just finished a subtask, an empty line might belong to it or the parent?
             // Simple logic: if indented 2 spaces, it's task note.
             if (currentTask.notes == null) currentTask.notes = "";
             currentTask.notes = (currentTask.notes! + "\n" + line.trim()).trim();
           } else {
             // Project Note (No indent or unknown)
             // Reset context if we hit a top-level line that isn't a task?
             // Actually, usually project notes come before tasks. 
             // If we have tasks, and we see unindented text, is it a new section or project note?
             // For now, treat as Project Note if we haven't started tasks, or if explicitly unindented.
             if (mutableTasks.isEmpty) {
                projectNotesBuffer.writeln(line);
             } else {
                // If we have tasks, unindented text might be weird. 
                // Let's assume it belongs to the project notes for now, or ignore.
                // But strict Markdown would say it breaks the list.
                // Let's append to project notes to be safe/simple.
                projectNotesBuffer.writeln(line);
             }
           }
        }
      }
    }

    // 3. Construct Project
    final projectId = frontmatter['id']?.toString() ?? _uuid.v4();
    return Project(
      id: projectId,
      title: title,
      tags: (frontmatter['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      notes: projectNotesBuffer.isNotEmpty ? projectNotesBuffer.toString().trim() : null,
      tasks: mutableTasks.map((t) => t.toTask(projectId)).toList(),
    );
  }

  static String toMarkdown(Project project) {
    // 1. Frontmatter
    final buffer = StringBuffer();
    buffer.writeln('---\n');
    buffer.writeln('id: ${project.id}\n');
    if (project.tags.isNotEmpty) {
      // Handle list formatting manually or trust toString? 
      // [tag1, tag2] is valid flow YAML
      buffer.writeln('tags: [${project.tags.join(', ')}]\n');
    }
    buffer.writeln('version: 1\n'); 
    buffer.writeln('---\n');
    buffer.writeln();

    // 2. Title
    buffer.writeln('# ${project.title}\n');
    buffer.writeln();

    // 3. Notes
    if (project.notes != null && project.notes!.isNotEmpty) {
      buffer.writeln(project.notes);
      buffer.writeln();
    }

    // 4. Tasks
    for (var task in project.tasks) {
      final checkbox = task.isCompleted ? '[x]' : '[ ]';
      buffer.writeln('- $checkbox ${task.title} <!-- id: ${task.id} -->');
      
      if (task.notes != null && task.notes!.isNotEmpty) {
         // Indent notes by 2 spaces
         final notesLines = task.notes!.split('\n');
         for (var line in notesLines) {
            buffer.writeln('  $line');
         }
      }

      if (task.subtasks.isNotEmpty) {
        for (var sub in task.subtasks) {
           final subCheckbox = sub.isCompleted ? '[x]' : '[ ]';
           buffer.writeln('  - $subCheckbox ${sub.title} <!-- id: ${sub.id} -->');
           
           if (sub.notes != null && sub.notes!.isNotEmpty) {
             final subNotesLines = sub.notes!.split('\n');
             for (var line in subNotesLines) {
                buffer.writeln('    $line');
             }
           }
        }
      }
      buffer.writeln(); // Add newline after task block
    }

    return buffer.toString();
  }
}
