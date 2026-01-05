import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/services/markdown_watcher_service.dart';
import 'package:flutter_app/data/repository/memory_storage_repository.dart';
import 'package:flutter_app/models/models.dart';

void main() {
  group('Race Condition Tests', () {
    late Directory tempDir;
    late DataService dataService;
    late MarkdownPersistenceService persistenceService;
    late MarkdownWatcherService watcherService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('race_test');
      final repository = MemoryStorageRepository();
      
      // Real persistence pointing to temp dir
      persistenceService = MarkdownPersistenceService(baseDir: tempDir.path);
      
      dataService = DataService(repository, persistenceService);
      
      // Real watcher pointing to temp dir
      watcherService = MarkdownWatcherService(dataService, baseDir: tempDir.path);
      dataService.setWatcher(watcherService);
      
      await dataService.initData();
      watcherService.start();
    });

    tearDown(() async {
      watcherService.stop();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Rapid typing does not create duplicate projects via watcher', () async {
      // Simulate rapid typing: "S", "Sy", "Syn", "Sync"
      // In the app, addProject is usually called ONCE when Enter is pressed.
      // However, if the user is typing in a field that auto-saves or if the logic
      // calls addProject multiple times (unlikely for "Add Project" but possible for "Update Title"),
      // we need to see what the user actually did.
      
      // The user said: "If I add a project named "sync test", it creates a new project after each letter i typed"
      // This implies the UI might be calling `addProject` or `updateTitle` on every keystroke?
      // Or maybe `upsertProject` is being called?
      
      // If the UI is "EditableColumn", `onAdd` is usually called on submission (Enter).
      // But let's assume the user logic somehow triggers updates.
      
      // Actually, if it's `addProject`, it creates a NEW ID every time.
      // If the user is typing in a "New Project" input field, and it submits on every character... that's a UI bug.
      // BUT, if the user means they created "S", then updated to "Sy", then "Syn"...
      // And the watcher saw the file change for "S", imported it as a NEW project because the ID didn't match?
      
      // Let's simulate:
      // 1. Create project "S"
      // 2. Update to "Sy"
      // 3. Update to "Syn"
      
      final id = await dataService.addProject("S");
      
      // Wait a tiny bit for IO
      await Future.delayed(const Duration(milliseconds: 50));
      
      dataService.updateTitle(id, "Sy");
      await Future.delayed(const Duration(milliseconds: 50));
      
      dataService.updateTitle(id, "Syn");
      await Future.delayed(const Duration(milliseconds: 50));
      
      dataService.updateTitle(id, "Sync");
      
      // Allow debounce and watcher to settle
      await Future.delayed(const Duration(seconds: 2));
      
      // We expect exactly ONE project in DataService
      expect(dataService.projects.length, 1);
      expect(dataService.projects.first.title, "Sync");
      
      // We expect exactly ONE file (or maybe the old ones got deleted/renamed?)
      // MarkdownPersistence renames the file if the title changes.
      // The old file should be gone.
      final dir = Directory('${tempDir.path}/todos/unsorted');
      final files = dir.listSync();
      
      // There should be only 'sync.md' (slugified)
      // If we have 's.md', 'sy.md', etc., then cleanup failed or watcher re-imported them.
      expect(files.length, 1);
      expect(files.first.path, endsWith('sync.md'));
    });
  });
}
