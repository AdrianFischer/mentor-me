import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../services/markdown_persistence_service.dart';
import '../data/repository/storage_repository.dart';
import '../data/repository/firebase_storage_repository.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return FirebaseStorageRepository();
});

final markdownPersistenceProvider = Provider<MarkdownPersistenceService>((ref) {
  return MarkdownPersistenceService();
});

final dataServiceProvider = ChangeNotifierProvider<DataService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final markdown = ref.watch(markdownPersistenceProvider);
  final service = DataService(storage, markdown);
  service.initData();
  return service;
});
