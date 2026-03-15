import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../services/node_service.dart';
import '../services/conversation_service.dart';
import '../services/memory_service.dart';
import '../services/knowledge_service.dart';
import '../services/agent_session_tracker.dart';
import '../services/file_system_service.dart';
import '../data/repository/storage_repository.dart';
import '../data/repository/in_memory_repository.dart';
import '../data/repository/rest_storage_repository.dart';
import '../app_config.dart';

final fileSystemServiceProvider = Provider<FileSystemService>((ref) {
  return FileSystemService();
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  if (AppConfig.useRemoteBackend) {
    return RestStorageRepository(baseUrl: AppConfig.backendUrl);
  }
  final fileService = ref.watch(fileSystemServiceProvider);
  return InMemoryRepository(fileService);
});

final nodeServiceProvider = ChangeNotifierProvider<NodeService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final service = NodeService(storage);
  service.initData();
  return service;
});

final conversationServiceProvider = ChangeNotifierProvider<ConversationService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final service = ConversationService(storage);
  service.initData();
  return service;
});

final memoryServiceProvider = ChangeNotifierProvider<MemoryService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final service = MemoryService(storage);
  service.initData();
  return service;
});

final knowledgeServiceProvider = ChangeNotifierProvider<KnowledgeService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return KnowledgeService(storage);
});

final agentSessionTrackerProvider = ChangeNotifierProvider<AgentSessionTracker>((ref) {
  return AgentSessionTracker();
});

final dataServiceProvider = ChangeNotifierProvider<DataService>((ref) {
  final nodeService = ref.watch(nodeServiceProvider);
  final conversationService = ref.watch(conversationServiceProvider);
  final memoryService = ref.watch(memoryServiceProvider);
  final knowledgeService = ref.watch(knowledgeServiceProvider);
  final sessionTracker = ref.watch(agentSessionTrackerProvider);

  final service = DataService(
    nodeService,
    conversationService,
    memoryService,
    knowledgeService,
    sessionTracker,
  );
  return service;
});
