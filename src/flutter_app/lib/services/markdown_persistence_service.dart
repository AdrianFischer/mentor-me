import 'dart:io';
import 'package:intl/intl.dart';
import '../config.dart';
import '../models/models.dart';

class MarkdownPersistenceService {
  final String? _baseDir;

  MarkdownPersistenceService() : _baseDir = Config.dataDir;

  bool get isEnabled => _baseDir != null;

  Future<void> saveTask(Task task, Project project) async {
    if (!isEnabled) return;
    
    // Generate slug from title
    final slug = _generateSlug(task.title);
    final timestamp = DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());
    final filename = '${timestamp}_$slug.md';
    // Use path separator
    final filePath = '$_baseDir/to_dos/$filename';
    
    final file = File(filePath);
    
    // Check if a file with this slug already exists to avoid duplicates?
    // For now, timestamp ensures uniqueness.
    
    final content = '''${task.title}
$slug
Task created from Flutter App in Project "${project.title}"

Summary
State: ${task.isCompleted ? 'Completed' : 'Pending'}
Focus: Creation

Log Book
- ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}: Created by App in Project "${project.title}".
''';

    try {
      final parentDir = Directory('$_baseDir/to_dos');
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      
      await file.writeAsString(content);
      await _updateOverview();
    } catch (e) {
      print('[MarkdownPersistence] Error saving task: $e');
    }
  }
  
  Future<void> _updateOverview() async {
      if (!isEnabled) return;
      
      final todoDir = Directory('$_baseDir/to_dos');
      if (!await todoDir.exists()) return;
      
      final entities = <_TodoEntry>[];
      
      try {
        await for (final file in todoDir.list()) {
            if (file is File && file.path.endsWith('.md')) {
                try {
                    final content = await file.readAsString();
                    final lines = content.split('\n');
                    if (lines.length < 2) continue;
                    
                    final desc = lines[0].trim();
                    final id = lines[1].trim();
                    // Extract State/Focus
                    String state = 'Unknown';
                    String focus = 'Unknown';
                    
                    for (var line in lines) {
                        if (line.startsWith('State:')) state = line.substring(6).trim();
                        if (line.startsWith('Focus:')) focus = line.substring(6).trim();
                    }
                    
                    entities.add(_TodoEntry(id, desc, state, focus));
                } catch (e) {
                    print('[MarkdownPersistence] Error parsing ${file.path}: $e');
                }
            }
        }
        
        final buffer = StringBuffer();
        buffer.writeln('# Project Overview');
        buffer.writeln();
        buffer.writeln('| **identifier**<br>Description | State | Focus |');
        buffer.writeln('|:---|:---|:---|');
        
        for (final e in entities) {
            buffer.writeln('| **${e.id}**<br>${e.desc} | ${e.state} | ${e.focus} |');
        }
        
        buffer.writeln();
        buffer.writeln('Last updated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
        
        final overviewFile = File('$_baseDir/overview.md');
        await overviewFile.writeAsString(buffer.toString());
      } catch (e) {
        print('[MarkdownPersistence] Error updating overview: $e');
      }
  }
  
  String _generateSlug(String title) {
    return title.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

class _TodoEntry {
    final String id;
    final String desc;
    final String state;
    final String focus;
    
    _TodoEntry(this.id, this.desc, this.state, this.focus);
}
