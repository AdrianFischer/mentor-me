import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../services/project_service.dart';
import '../services/conversation_service.dart';
import '../services/memory_service.dart';
import '../services/knowledge_service.dart';
import '../services/agent_session_tracker.dart';
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

final projectServiceProvider = ChangeNotifierProvider<ProjectService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final service = ProjectService(storage);
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
  final projectService = ref.watch(projectServiceProvider);
  final conversationService = ref.watch(conversationServiceProvider);
  final memoryService = ref.watch(memoryServiceProvider);
  final knowledgeService = ref.watch(knowledgeServiceProvider);
  final sessionTracker = ref.watch(agentSessionTrackerProvider);
  
  final service = DataService(
    projectService,
    conversationService,
    memoryService,
    knowledgeService,
    sessionTracker,
  );
  return service;
});
