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
  final Map<String, DateTime> _recentInternalWrites = {};

  FileSystemService({String? baseDir}) : _baseDir = baseDir ?? Config.dataDir;

  bool get isEnabled => _baseDir != null;

  @override
  Future<List<Project>> loadAllProjects() async {
    final projects = <Project>[];
    if (!isEnabled) return projects;

    final dir = Directory('$_baseDir/todos');
    if (!await dir.exists()) return projects;

    final seenIds = <String>{};

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md') && !entity.path.endsWith('README.md')) {
        try {
          final content = await entity.readAsString();
          final project = MarkdownParser.parseProject(content);
          
          if (!seenIds.contains(project.id)) {
            projects.add(project);
            seenIds.add(project.id);
          } else {
             print('Duplicate project ID found: ${project.id} in ${entity.path}. Skipping.');
          }
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
    
    final category = _getCategory(project);
    final fileName = _generateFileName(project.title);
    final filePath = '$_baseDir/todos/$category/$fileName.md';
    
    // Normalize path for consistency
    final normalizedPath = File(filePath).absolute.path;
    _recentInternalWrites[normalizedPath] = DateTime.now();

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
    return dir.watch(recursive: true)
      .transform(_debounce(const Duration(milliseconds: 200)))
      .asyncMap((event) async {
      if (event.path.endsWith('.md')) {
         final absolutePath = File(event.path).absolute.path;
         final lastWrite = _recentInternalWrites[absolutePath];
         
         if (lastWrite != null) {
            final difference = DateTime.now().difference(lastWrite);
            if (difference.inSeconds < 2) {
               print("[DEBUG] FileSystemService: Ignoring internal write event for $absolutePath (diff: ${difference.inMilliseconds}ms)");
               return <Project>[];
            }
         }

         print("[DEBUG] FileSystemService: External change detected for ${event.path}. Reloading...");
         final projects = await loadAllProjects();
         return projects;
      }
      return <Project>[]; 
    }).where((list) => list.isNotEmpty);
  }

  // Simple debounce transformer
  StreamTransformer<T, T> _debounce<T>(Duration duration) {
    return StreamTransformer<T, T>((input, cancelOnError) {
      StreamController<T>? controller;
      StreamSubscription<T>? subscription;
      Timer? timer;

      controller = StreamController<T>(
        onListen: () {
          subscription = input.listen(
            (event) {
              timer?.cancel();
              timer = Timer(duration, () {
                if (!controller!.isClosed) {
                  controller.add(event);
                }
              });
            },
            onError: controller?.addError,
            onDone: () {
               timer?.cancel();
               controller?.close();
            },
            cancelOnError: cancelOnError,
          );
        },
        onPause: () => subscription?.pause(),
        onResume: () => subscription?.resume(),
        onCancel: () {
          timer?.cancel();
          return subscription?.cancel();
        },
      );

      return controller.stream.listen(null);
    });
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
