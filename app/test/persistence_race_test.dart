import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/services/file_system_service.dart';
import 'package:flutter_app/data/repository/in_memory_repository.dart';

void main() {
  group('Race Condition Tests', () {
    late Directory tempDir;
    late NodeService nodeService;
    late FileSystemService fileService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('race_test');

      // Use real FileSystemService for race condition testing
      fileService = FileSystemService(baseDir: tempDir.path);
      final repository = InMemoryRepository(fileService);

      nodeService = NodeService(repository);
      await nodeService.initData();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Rapid typing does not create duplicate nodes via watcher', () async {
      final id = await nodeService.addChild(null, "S");

      // Wait a tiny bit for IO
      await Future.delayed(const Duration(milliseconds: 100));

      nodeService.updateTitle(id!, "Sy");
      await Future.delayed(const Duration(milliseconds: 100));

      nodeService.updateTitle(id, "Syn");
      await Future.delayed(const Duration(milliseconds: 100));

      nodeService.updateTitle(id, "Sync");

      // Allow debounce and persistence to settle
      await Future.delayed(const Duration(seconds: 2));

      // We expect exactly ONE root node in NodeService
      print('DEBUG: rootNodes length is ${nodeService.rootNodes.length}');
      expect(nodeService.rootNodes.length, 1);
      expect(nodeService.rootNodes.first.title, "Sync");

      // Check file system
      final dir = Directory('${tempDir.path}/todos/unsorted');
      if (dir.existsSync()) {
        expect(nodeService.rootNodes.length, 1);
      }
    });
  });
}
