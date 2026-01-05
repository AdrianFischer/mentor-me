import 'dart:async';
import 'dart:io';
import '../config.dart';
import '../models/models.dart';
import '../utils/markdown_parser.dart';
import 'file_persistence_service.dart';

class FileSystemService implements FilePersistenceService {
  final String? _baseDir;
  final _projectController = StreamController<List<Project>>.broadcast();
  
  // Track internal writes to prevent loops
  // Map<ProjectId, LastWriteTime>
  final Map<String, DateTime> _lastWriteTimes = {};

  FileSystemService({String? baseDir}) : _baseDir = baseDir ?? Config.dataDir;

  bool get isEnabled => _baseDir != null;

  @override
  Future<List<Project>> loadAllProjects() async {
    final projects = <Project>[];
    if (!isEnabled) return projects;

    final dir = Directory('$_baseDir/todos');
    if (!await dir.exists()) return projects;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md') && !entity.path.endsWith('README.md')) {
        try {
          final content = await entity.readAsString();
          projects.add(MarkdownParser.parseProject(content));
        } catch (e) {
          print('Error loading file ${entity.path}: $e');
        }
      }
    }
    return projects;
  }

  @override
  Future<void> saveProject(Project project) async {
    if (!isEnabled) return;
    
    _lastWriteTimes[project.id] = DateTime.now();

    final category = _getCategory(project);
    final fileName = _generateFileName(project.title);
    final filePath = '$_baseDir/todos/$category/$fileName.md';
    final file = File(filePath);

    // TODO: Handle renaming (if title changed, old file needs deletion)
    // For now, we assume simple overwrite or we need to track old paths.
    // In "File-First", the file name IS the identity in a way, but we have internal ID.
    // Ideally we find the old file by ID and delete it if path is different.
    
    // Simple approach for now:
    await _ensureDirectory(file.parent);
    
    final markdown = MarkdownParser.toMarkdown(project);
    await file.writeAsString(markdown);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    if (!isEnabled) return;
    
    // Find file by ID
    final file = await _findFileByProjectId(projectId);
    if (file != null) {
      await file.delete();
    }
  }

  @override
  Stream<List<Project>> watchProjects() {
    if (!isEnabled) return Stream.value([]);
    
    final dir = Directory('$_baseDir/todos');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // We can emit the full list on every change, or diffs.
    // The interface returns Stream<List<Project>>.
    // This implies we reload ALL projects on change? That's heavy.
    // Maybe the interface should be Stream<ProjectChange>?
    // But for now, let's stick to the interface or just trigger a reload signal.
    
    // Actually, FilePersistenceService interface I defined:
    // Stream<List<Project>> watchProjects();
    
    // Implementing a full reload on every event:
    return dir.watch(recursive: true).asyncMap((event) async {
      // Debounce/Filter here?
      // Check if it's our own write
      if (event.path.endsWith('.md')) {
         // Should we check _lastWriteTimes?
         // It's hard to correlate FileSystemEvent to specific Project ID without parsing.
         
         // Let's just reload everything for now (Inefficient but correct for MVP)
         return await loadAllProjects();
      }
      return <Project>[]; 
    }).where((list) => list.isNotEmpty);
  }

  // --- Helpers ---

  String _getCategory(Project project) {
    if (project.tags.isNotEmpty) {
      return project.tags.first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    }
    return 'unsorted';
  }

  String _generateFileName(String title) {
    return title.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<void> _ensureDirectory(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<File?> _findFileByProjectId(String projectId) async {
    final dir = Directory('$_baseDir/todos');
    if (!await dir.exists()) return null;
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final content = await entity.readAsString();
          // Quick parse or regex
          if (content.contains('id: $projectId')) {
             return entity;
          }
        } catch (_) {}
      }
    }
    return null;
  }
}
