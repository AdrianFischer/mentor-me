import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../services/markdown_persistence_service.dart';
import '../services/markdown_watcher_service.dart';
import '../data/repository/storage_repository.dart';
import '../data/repository/in_memory_repository.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return InMemoryRepository();
});

final markdownPersistenceProvider = Provider<MarkdownPersistenceService>((ref) {
  return MarkdownPersistenceService();
});

final markdownWatcherProvider = Provider<MarkdownWatcherService>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  final watcher = MarkdownWatcherService(dataService);
  return watcher;
});

final startWatcherProvider = Provider<void>((ref) {
  final service = ref.watch(dataServiceProvider);
  final watcher = ref.watch(markdownWatcherProvider);
  service.setWatcher(watcher);
  watcher.start();
});

final dataServiceProvider = ChangeNotifierProvider<DataService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final markdown = ref.watch(markdownPersistenceProvider);
  final service = DataService(storage, markdown);
  service.initData();
  return service;
});

