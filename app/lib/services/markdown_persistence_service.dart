import 'dart:io';
import 'dart:convert';
import '../config.dart';
import '../models/models.dart';
import 'markdown_converter.dart';

class MarkdownPersistenceService {
  final String? _baseDir;
  final MarkdownConverter _converter = MarkdownConverter();

  MarkdownPersistenceService({String? baseDir}) : _baseDir = baseDir ?? Config.dataDir;

  bool get isEnabled => _baseDir != null;

  Future<void> saveProject(Project project) async {
    if (!isEnabled) {
      print('[MarkdownPersistence] Service disabled: No data directory configured.');
      return;
    }
    
    // 1. Find existing file for this project ID to handle renaming
    await _deleteFileForProjectId(project.id);
    
    final markdown = _converter.projectToMarkdown(project);
    
    // Determine category from first tag
    String category = 'unsorted';
    if (project.tags.isNotEmpty) {
      category = project.tags.first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    }
    
    final fileName = _generateFileName(project.title);
    final filePath = '$_baseDir/todos/$category/$fileName.md';
    
    try {
      final file = File(filePath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      
      await file.writeAsString(markdown);
      print('[MarkdownPersistence] Saved project "${project.title}" to $filePath');
    } catch (e) {
      print('[MarkdownPersistence] Error saving project: $e');
    }
  }

  Future<void> _deleteFileForProjectId(String projectId) async {
    // Brute-force search: In a real app, we might want a cache or index.
    // Since we don't have many files yet, simple directory walk is fine.
    try {
      final dir = Directory('$_baseDir/todos');
      if (!await dir.exists()) return;
      
      await for (final file in dir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.md')) {
          // Read first few lines to find ID?
          // To be efficient, we assume ID is in the first 5 lines.
          final stream = file.openRead();
          try {
             final lines = await stream.transform(SystemEncoding().decoder).transform(const LineSplitter()).take(5).toList();
             for (final line in lines) {
                if (line.contains('<!-- id: $projectId -->')) {
                   print('[MarkdownPersistence] Deleting old file: ${file.path}');
                   await file.delete();
                   return;
                }
             }
          } catch (e) {
             // Ignore read errors
          }
        }
      }
    } catch (e) {
      print('[MarkdownPersistence] Error scanning for old files: $e');
    }
  }

  Future<void> deleteProject(Project project) async {
    if (!isEnabled) return;
    await _deleteFileForProjectId(project.id);
  }

  String _generateFileName(String title) {
    return title.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }
}