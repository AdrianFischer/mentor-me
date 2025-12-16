import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../data/repository/storage_repository.dart';
import '../data/repository/isar_storage_repository.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return IsarStorageRepository();
});

final dataServiceProvider = ChangeNotifierProvider<DataService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final service = DataService(storage);
  service.initData();
  return service;
});
