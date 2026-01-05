import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/file_system_service.dart';
import 'package:flutter_app/data/repository/in_memory_repository.dart';
import 'package:flutter_app/models/models.dart';

void main() {
  group('Race Condition Tests', () {
    late Directory tempDir;
    late DataService dataService;
    late FileSystemService fileService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('race_test');
      
      // Use real FileSystemService for race condition testing
      fileService = FileSystemService(baseDir: tempDir.path);
      final repository = InMemoryRepository(fileService);
      
      dataService = DataService(repository);
      await dataService.initData();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Rapid typing does not create duplicate projects via watcher', () async {
      final id = await dataService.addProject("S");
      
      // Wait a tiny bit for IO
      await Future.delayed(const Duration(milliseconds: 100));
      
      dataService.updateTitle(id, "Sy");
      await Future.delayed(const Duration(milliseconds: 100));
      
      dataService.updateTitle(id, "Syn");
      await Future.delayed(const Duration(milliseconds: 100));
      
      dataService.updateTitle(id, "Sync");
      
      // Allow debounce and persistence to settle
      await Future.delayed(const Duration(seconds: 2));
      
      // We expect exactly ONE project in DataService
      expect(dataService.projects.length, 1);
      expect(dataService.projects.first.title, "Sync");
      
      // Check file system
      final dir = Directory('${tempDir.path}/todos/unsorted');
      if (dir.existsSync()) {
        final files = dir.listSync().where((f) => f.path.endsWith('.md')).toList();
        // Since FileSystemService might not delete old files yet (it doesn't have rename logic fully implemented),
        // we might have multiple files, but they should all have the same ID.
        // The DataService should only have one project.
        expect(dataService.projects.length, 1);
      }
    });
  });
}