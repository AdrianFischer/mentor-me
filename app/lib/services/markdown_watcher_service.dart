import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../config.dart';
import 'data_service.dart';
import 'markdown_converter.dart';

class MarkdownWatcherService {
  final DataService _dataService;
  final MarkdownConverter _converter = MarkdownConverter();
  final String? _baseDir;
  StreamSubscription<FileSystemEvent>? _subscription;
  
  // Cache to track path -> projectId mapping for deletions
  final Map<String, String> _pathCache = {};
  
  // To prevent infinite loops (Isar -> Markdown -> Isar)
  DateTime? _lastSelfWrite;

  MarkdownWatcherService(this._dataService, {String? baseDir}) : _baseDir = baseDir ?? Config.dataDir;

  bool get isEnabled => _baseDir != null;

  void start() async {
    if (!isEnabled) return;

    final dir = Directory('$_baseDir/todos');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    
    // Initial scan to build cache
    await _buildCache(dir);

    print('[MarkdownWatcher] Starting watcher for ${dir.path}');
    _subscription = dir.watch(recursive: true).listen(_onEvent);
  }
  
  Future<void> _buildCache(Directory dir) async {
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.md')) {
          await _addToCache(entity.path);
        }
      }
    } catch (e) {
      print('[MarkdownWatcher] Error building cache: $e');
    }
  }
  
  Future<void> _addToCache(String path) async {
    try {
      final file = File(path);
      // Read just enough to get the ID
      final stream = file.openRead();
      final lines = await stream.transform(SystemEncoding().decoder).transform(const LineSplitter()).take(5).toList();
      for (final line in lines) {
        if (line.trim().startsWith('<!-- id:') && line.trim().endsWith('-->')) {
           final id = line.trim().substring(8, line.trim().length - 3).trim();
           _pathCache[path] = id;
           return;
        }
      }
    } catch (_) {}
  }

  void stop() {
    _subscription?.cancel();
  }

  void recordSelfWrite() {
    _lastSelfWrite = DateTime.now();
  }

  Future<void> _onEvent(FileSystemEvent event) async {
    // Basic debounce/ignore self-writes
    if (_lastSelfWrite != null && DateTime.now().difference(_lastSelfWrite!) < const Duration(seconds: 2)) {
      // Likely a write from the app itself
      // But if it's a delete initiated by the app, we should update cache
      if (event is FileSystemDeleteEvent) {
         _pathCache.remove(event.path);
      } else if (event.path.endsWith('.md')) {
         // Update cache for write/create
         await _addToCache(event.path);
      }
      return;
    }

    if (event.path.endsWith('.md')) {
      if (event is FileSystemModifyEvent || event is FileSystemCreateEvent) {
        print('[MarkdownWatcher] Change detected in ${event.path}');
        await _syncFileToData(event.path);
        await _addToCache(event.path);
      } else if (event is FileSystemDeleteEvent) {
        print('[MarkdownWatcher] Deletion detected for ${event.path}');
        await _handleDeletion(event.path);
      }
    }
  }
  
  Future<void> _handleDeletion(String path) async {
    final projectId = _pathCache[path];
    if (projectId != null) {
      print('[MarkdownWatcher] Deleting project $projectId from app');
      _dataService.deleteItem(projectId);
      _pathCache.remove(path);
    } else {
      print('[MarkdownWatcher] Unknown file deleted: $path');
    }
  }

  Future<void> _syncFileToData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      
      // We need to find if this project already exists in DataService to preserve ID
      final projectFromMd = _converter.markdownToProject(content);
      
      // Use ID from markdown if available (it should be)
      final existingProject = _dataService.projects.firstWhere(
        (p) => p.id == projectFromMd.id,
        orElse: () => _dataService.projects.firstWhere(
           (p) => p.title == projectFromMd.title, 
           orElse: () => projectFromMd
        ),
      );

      final mergedProject = projectFromMd.copyWith(id: existingProject.id);
      
      _dataService.upsertProject(mergedProject);
      for (final task in mergedProject.tasks) {
        _dataService.upsertTask(task.copyWith(projectId: mergedProject.id));
      }
      
    } catch (e) {
      print('[MarkdownWatcher] Error syncing file $filePath: $e');
    }
  }
}
