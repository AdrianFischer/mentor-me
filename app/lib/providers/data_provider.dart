import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../services/file_system_service.dart';
import '../data/repository/storage_repository.dart';
import '../data/repository/in_memory_repository.dart';

final fileSystemServiceProvider = Provider<FileSystemService>((ref) {
  return FileSystemService();
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final fileService = ref.watch(fileSystemServiceProvider);
  return InMemoryRepository(fileService);
});

final dataServiceProvider = ChangeNotifierProvider<DataService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final service = DataService(storage);
  service.initData();
  return service;
});

