import 'dart:async';
import 'dart:io';

import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/services/file_system_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileSystemService Tests', () {
    late Directory tempDir;
    late FileSystemService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flutter_app_test_fs');
      service = FileSystemService(baseDir: tempDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Test 11: File Watcher Loop Prevention Test', () async {
      // Create the service and start watching
      final stream = service.watchNodes();
      
      // We will listen to the stream. We expect 0 events because internal writes are ignored.
      // Actually, watchNodes returns a Stream<List<Node>> that fires when an *external* change happens.
      // Wait for the stream to initialize.
      bool eventFired = false;
      final sub = stream.listen((nodes) {
        eventFired = true;
      });

      // Wait a moment for watcher to set up
      await Future.delayed(const Duration(milliseconds: 500));

      final node = Node(
        id: 'test-node-1',
        title: 'Initial Title',
      );

      // Perform internal write
      await service.saveNode(node);

      // Wait for debounce period + a little buffer
      await Future.delayed(const Duration(milliseconds: 1000));

      // Assert no event was fired
      expect(eventFired, isFalse, reason: 'Internal write should not trigger a reload event.');

      await sub.cancel();
    });

    test('Test 12: File Renaming Duplication Test', () async {
      final node = Node(
        id: 'test-node-2',
        title: 'Original Title',
      );

      // Save initial node
      await service.saveNode(node);
      
      // Verify file exists
      final nodes1 = await service.loadAllNodes();
      expect(nodes1.length, 1);
      expect(nodes1.first.title, 'Original Title');

      // Check the actual file
      final todosDir = Directory('${tempDir.path}/todos/unsorted');
      final files1 = todosDir.listSync().whereType<File>().toList();
      expect(files1.length, 1);
      expect(files1.first.path.endsWith('original_title.md'), isTrue);

      // Update node title (which changes filename)
      final updatedNode = node.copyWith(title: 'Updated Title');
      await service.saveNode(updatedNode);

      // Verify old file is deleted and new one exists
      final nodes2 = await service.loadAllNodes();
      expect(nodes2.length, 1);
      expect(nodes2.first.title, 'Updated Title');

      final files2 = todosDir.listSync().whereType<File>().toList();
      expect(files2.length, 1, reason: 'Old file should be deleted, leaving only 1 file.');
      expect(files2.first.path.endsWith('updated_title.md'), isTrue);
    });
  });
}
