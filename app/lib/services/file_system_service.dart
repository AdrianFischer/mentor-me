import 'dart:async';
import 'dart:io';
import '../config.dart';
import '../models/node.dart';
import '../utils/markdown_parser.dart';
import 'file_persistence_service.dart';

class FileSystemService implements FilePersistenceService {
  final String? _baseDir;

  // Track internal writes to prevent loops
  final Map<String, DateTime> _recentInternalWrites = {};

  FileSystemService({String? baseDir}) : _baseDir = baseDir ?? Config.dataDir;

  bool get isEnabled => _baseDir != null;

  @override
  Future<List<Node>> loadAllNodes() async {
    final nodes = <Node>[];
    if (!isEnabled) return nodes;

    final dir = Directory('$_baseDir/todos');
    if (!await dir.exists()) return nodes;

    final seenIds = <String>{};

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md') && !entity.path.endsWith('README.md')) {
        try {
          final content = await entity.readAsString();
          final node = MarkdownParser.parseNode(content);

          if (!seenIds.contains(node.id)) {
            nodes.add(node);
            seenIds.add(node.id);
          } else {
             print('Duplicate node ID found: ${node.id} in ${entity.path}. Skipping.');
          }
        } catch (e) {
          print('Error loading file ${entity.path}: $e');
        }
      }
    }
    return nodes;
  }

  @override
  Future<void> saveNode(Node node) async {
    if (!isEnabled) return;

    final category = _getCategory(node);
    final fileName = _generateFileName(node.title);
    final filePath = '$_baseDir/todos/$category/$fileName.md';

    final file = File(filePath);
    final normalizedPath = file.absolute.path;

    // Handle renaming (if title changed, old file needs deletion)
    final oldFile = await _findFileByNodeId(node.id);
    if (oldFile != null && oldFile.absolute.path != normalizedPath) {
      _recentInternalWrites[oldFile.absolute.path] = DateTime.now();
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    _recentInternalWrites[normalizedPath] = DateTime.now();

    await _ensureDirectory(file.parent);

    final markdown = MarkdownParser.nodeToMarkdown(node);
    await file.writeAsString(markdown);
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    if (!isEnabled) return;

    // Find file by ID
    final file = await _findFileByNodeId(nodeId);
    if (file != null && await file.exists()) {
      _recentInternalWrites[file.absolute.path] = DateTime.now();
      await file.delete();
    }
  }

  @override
  Stream<List<Node>> watchNodes() {
    if (!isEnabled) return Stream.value([]);

    final dir = Directory('$_baseDir/todos');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    return dir.watch(recursive: true)
      .where((event) {
         if (!event.path.endsWith('.md')) return false;
         final absolutePath = File(event.path).absolute.path;
         final lastWrite = _recentInternalWrites[absolutePath];

         if (lastWrite != null) {
            final difference = DateTime.now().difference(lastWrite);
            if (difference.inSeconds < 2) {
               return false; // Ignore internal write
            }
         }
         return true;
      })
      .transform(_debounce(const Duration(milliseconds: 500)))
      .asyncMap((_) async {
         print("[DEBUG] FileSystemService: External change detected. Reloading...");
         return await loadAllNodes();
      });
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

  String _getCategory(Node node) {
    if (node.tags.isNotEmpty) {
      return node.tags.first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
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

  Future<File?> _findFileByNodeId(String nodeId) async {
    final dir = Directory('$_baseDir/todos');
    if (!await dir.exists()) return null;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final content = await entity.readAsString();
          // Quick parse or regex
          if (content.contains('id: $nodeId')) {
             return entity;
          }
        } catch (_) {}
      }
    }
    return null;
  }
}
