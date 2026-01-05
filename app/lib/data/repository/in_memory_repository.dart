import 'dart:async';
import '../../models/models.dart';
import '../../models/ai_models.dart';
import '../../services/file_persistence_service.dart';
import 'storage_repository.dart';

/// A non-persistent, in-memory implementation of StorageRepository.
/// Acts as a cache that delegates persistence to FilePersistenceService.
class InMemoryRepository implements StorageRepository {
  final FilePersistenceService _fileService;
  final List<Project> _projects = [];
  final List<Conversation> _conversations = [];
  final List<ChatMessage> _chatHistory = [];
  final List<Knowledge> _knowledgeBase = [];
  
  final _dataChangeController = StreamController<void>.broadcast();
  StreamSubscription? _watcherSubscription;

  InMemoryRepository(this._fileService);

  @override
  Stream<void> get onDataChanged => _dataChangeController.stream;

  @override
  Future<void> init() async {
    // 1. Initial Load
    try {
      final loadedProjects = await _fileService.loadAllProjects();
      _projects.clear();
      _projects.addAll(loadedProjects);
      print('InMemoryRepository loaded ${_projects.length} projects.');
    } catch (e) {
      print('InMemoryRepository init error: $e');
    }

    // 2. Start Watcher
    _watcherSubscription = _fileService.watchProjects().listen((updatedProjects) {
       // Simple Strategy: Replace all?
       // Ideally we merge, but "File First" means File is Truth.
       // If we replace all, we might lose in-memory cursor/state if not careful.
       // But Project objects are immutable (Freezed).
       
       // Optimization: Only update if changed?
       _projects.clear();
       _projects.addAll(updatedProjects);
       
       // Notify app to redraw
       _dataChangeController.add(null); 
    });
  }
  
  void dispose() {
    _watcherSubscription?.cancel();
    _dataChangeController.close();
  }

  // --- Projects ---

  @override
  Future<List<Project>> getAllProjects() async {
    return List.unmodifiable(_projects);
  }

  @override
  Future<void> saveProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    
    // Write-Through
    await _fileService.saveProject(project);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    await _fileService.deleteProject(projectId);
  }

  // --- Tasks ---

  @override
  Future<void> saveTask(Task task) async {
    if (task.projectId == null) return;

    final pIndex = _projects.indexWhere((p) => p.id == task.projectId);
    if (pIndex == -1) return;

    final project = _projects[pIndex];
    final tIndex = project.tasks.indexWhere((t) => t.id == task.id);

    List<Task> newTasks = List.from(project.tasks);
    if (tIndex != -1) {
      newTasks[tIndex] = task;
    } else {
      newTasks.add(task);
    }

    final newProject = project.copyWith(tasks: newTasks);
    _projects[pIndex] = newProject;
    
    // Write-Through
    await _fileService.saveProject(newProject);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final tIndex = project.tasks.indexWhere((t) => t.id == taskId);
      if (tIndex != -1) {
        final newTasks = List<Task>.from(project.tasks)..removeAt(tIndex);
        final newProject = project.copyWith(tasks: newTasks);
        _projects[i] = newProject;
        
        // Write-Through
        await _fileService.saveProject(newProject);
        return;
      }
    }
  }
  
  // ... Rest of the methods (Conversations, Chat, Knowledge) remain in-memory for now ...
  // (Assuming file persistence is only for Projects currently)

  @override
  Future<List<Conversation>> getAllConversations() async {
    return List.unmodifiable(_conversations);
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    _chatHistory.removeWhere((m) => m.conversationId == conversationId);
  }

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    _chatHistory.add(message);
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      return _chatHistory.where((m) => m.conversationId == conversationId).toList();
    }
    return _chatHistory.toList(); 
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      _chatHistory.removeWhere((m) => m.conversationId == conversationId);
    } else {
      _chatHistory.clear();
    }
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    return List.unmodifiable(_knowledgeBase);
  }

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
     _knowledgeBase.add(knowledge);
  }

  @override
  Future<void> deleteKnowledge(String id) async {
     // _knowledgeBase.removeWhere((k) => k.id == id);
  }
}
