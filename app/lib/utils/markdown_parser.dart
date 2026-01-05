import 'package:yaml/yaml.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class MarkdownParser {
  static const _uuid = Uuid();

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
    List<Task> tasks = [];
    StringBuffer notesBuffer = StringBuffer();

    final lines = body.split('\n');
    bool titleFound = false;

    for (var line in lines) {
      final trimmed = line.trim();
      
      // Skip empty lines if we haven't found title yet
      if (!titleFound && trimmed.isEmpty) continue;

      if (!titleFound && trimmed.startsWith('# ')) {
        title = trimmed.substring(2).trim();
        titleFound = true;
        continue;
      }

      if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ')) {
        // It's a task
        final isCompleted = trimmed.startsWith('- [x] ');
        final taskTitle = trimmed.substring(6).trim();
        // TODO: Extract ID if present, else generate
        final id = _uuid.v4(); 
        
        tasks.add(Task(
          id: id, 
          title: taskTitle, 
          isCompleted: isCompleted,
        ));
      } else {
        if (titleFound) {
          // It's part of notes
          notesBuffer.writeln(line);
        }
      }
    }

    // 3. Construct Project
    return Project(
      id: frontmatter['id']?.toString() ?? _uuid.v4(),
      title: title,
      tags: (frontmatter['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      notes: notesBuffer.isNotEmpty ? notesBuffer.toString().trim() : null,
      tasks: tasks,
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
      buffer.writeln('- $checkbox ${task.title}\n');
    }

    return buffer.toString();
  }
}
