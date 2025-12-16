import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../config.dart';
import '../models/models.dart';

class MarkdownPersistenceService {
  String? _dataDir;

  Stream<void> get onDataChanged => const Stream.empty();

  Future<void> init() async {
    _dataDir = Config.dataDir;
    if (_dataDir == null) {
      final docs = await getApplicationDocumentsDirectory();
      _dataDir = docs.path;
    }
    print("MarkdownPersistenceService initialized with dataDir: $_dataDir");
  }

  Future<List<Task>> loadTasks() async {
    if (_dataDir == null) await init();
    
    final tasks = <Task>[];
    final todoDir = Directory(path.join(_dataDir!, 'to_dos'));

    if (!await todoDir.exists()) {
      print("to_dos directory not found at ${todoDir.path}");
      return [];
    }

    try {
      final files = todoDir.listSync().whereType<File>().where((f) => f.path.endsWith('.md'));
      
      for (final file in files) {
        try {
          final task = await _parseTaskFile(file);
          if (task != null) {
            tasks.add(task);
          }
        } catch (e) {
          print("Error parsing file ${file.path}: $e");
        }
      }
    } catch (e) {
      print("Error listing files: $e");
    }

    return tasks;
  }

  Future<Task?> _parseTaskFile(File file) async {
    // Keep legacy parsing for reading
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      if (lines.length < 2) return null; // Need at least Title and ID

      // Check for YAML frontmatter (skip for now as per plan simplicity)
      if (lines[0].trim() == '---') return null;

      final title = lines[0].trim();
      final id = lines[1].trim();

      bool isCompleted = false;
      // Simple state check
      for (var line in lines) {
        if (line.trim().toLowerCase().startsWith('state: completed')) {
          isCompleted = true;
          break;
        }
      }

      return Task(
        id: id,
        title: title,
        isCompleted: isCompleted,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveTask(Task task) async {
    if (_dataDir == null) await init();
    
    final todoDir = Directory(path.join(_dataDir!, 'to_dos'));
    if (!await todoDir.exists()) {
       // Only create if we are sure? 
       // For "Handover", we assume the folder exists in the workspace.
       print("Warning: to_dos directory does not exist at ${todoDir.path}");
       return;
    }

    // 1. Try to find existing file
    File? targetFile;
    try {
      await for (final entity in todoDir.list()) {
        if (entity is File && entity.path.endsWith('${task.id}.md')) {
          targetFile = entity;
          break;
        }
      }
    } catch (e) {
      print("Error listing files for save: $e");
    }

    final now = DateTime.now();

    if (targetFile != null) {
      // Update existing (Simple update: Title + State)
      final content = await targetFile.readAsString();
      var lines = content.split('\n');
      
      if (lines.isNotEmpty) lines[0] = task.title;
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith("State:")) {
          lines[i] = "State: ${task.isCompleted ? 'Completed' : 'In Progress'}";
          break;
        }
      }
      
      await targetFile.writeAsString(lines.join('\n'));
      print("Updated task file: ${targetFile.path}");

    } else {
      // Create NEW file (Simple Handover)
      final timestamp = "${now.year}_${now.month.toString().padLeft(2,'0')}_${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}";
      final filename = "${timestamp}_${task.id}.md";
      final file = File(path.join(todoDir.path, filename));

      final content = """
${task.title}
${task.id}
Created via App

Summary
State: ${task.isCompleted ? 'Completed' : 'In Progress'}
Focus: Initial Scope

Log Book
${now.toString().substring(0, 16)}: Task created via App.
""";
      await file.writeAsString(content);
      print("Created new task file: ${file.path}");
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_dataDir == null) await init();
    
    final todoDir = Directory(path.join(_dataDir!, 'to_dos'));
    if (!await todoDir.exists()) return;

    try {
      await for (final entity in todoDir.list()) {
        if (entity is File && entity.path.endsWith('$taskId.md')) {
          await entity.delete();
          print("Deleted task file: ${entity.path}");
          return;
        }
      }
      print("Task file not found for deletion: $taskId");
    } catch (e) {
      print("Error deleting task file: $e");
    }
  }
}
