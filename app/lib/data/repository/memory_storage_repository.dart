import 'dart:async';
import '../../models/models.dart';
import '../../models/ai_models.dart';
import 'storage_repository.dart';

class MemoryStorageRepository implements StorageRepository {
  final List<Project> _projects = [];
  final List<Conversation> _conversations = [];
  final Map<String, List<ChatMessage>> _chatHistories = {};
  final List<Knowledge> _knowledgeBase = [];
  final List<Memory> _memories = [];
  final StreamController<void> _dataChangeController = StreamController<void>.broadcast();

  @override
  Stream<void> get onDataChanged => _dataChangeController.stream;

  @override
  Future<void> init() async {
    // Already initialized in memory
  }

  @override
  Future<List<Project>> getAllProjects() async {
    return List.unmodifiable(_projects);
  }

  @override
  Future<void> saveProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    _dataChangeController.add(null);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    _dataChangeController.add(null);
  }

  @override
  Future<void> saveTask(Task task) async {
    // Find project
    for (var i = 0; i < _projects.length; i++) {
      if (_projects[i].id == task.projectId) {
        final tasks = List<Task>.from(_projects[i].tasks);
        final taskIndex = tasks.indexWhere((t) => t.id == task.id);
        if (taskIndex >= 0) {
          tasks[taskIndex] = task;
        } else {
          tasks.add(task);
        }
        _projects[i] = _projects[i].copyWith(tasks: tasks);
        break;
      }
    }
    _dataChangeController.add(null);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    for (var i = 0; i < _projects.length; i++) {
      final tasks = List<Task>.from(_projects[i].tasks);
      final initialLength = tasks.length;
      tasks.removeWhere((t) => t.id == taskId);
      if (tasks.length != initialLength) {
        _projects[i] = _projects[i].copyWith(tasks: tasks);
        break;
      }
    }
    _dataChangeController.add(null);
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
  }

  @override
  Future<List<Conversation>> getAllConversations() async {
    return List.unmodifiable(_conversations);
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
  }

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    final key = message.conversationId ?? mode;
    _chatHistories.putIfAbsent(key, () => []).add(message);
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    final key = conversationId ?? mode;
    return List.unmodifiable(_chatHistories[key] ?? []);
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    final key = conversationId ?? mode;
    _chatHistories[key] = [];
  }

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
    final index = _knowledgeBase.indexWhere((k) => k.id == knowledge.id);
    if (index >= 0) {
      _knowledgeBase[index] = knowledge;
    } else {
      _knowledgeBase.add(knowledge);
    }
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    return List.unmodifiable(_knowledgeBase);
  }

  @override
  Future<void> deleteKnowledge(String id) async {
    _knowledgeBase.removeWhere((k) => k.id == id);
  }

  @override
  Future<void> saveMemory(Memory memory) async {
    final index = _memories.indexWhere((m) => m.id == memory.id);
    if (index >= 0) {
      _memories[index] = memory;
    } else {
      _memories.add(memory);
    }
    _dataChangeController.add(null);
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    return List.unmodifiable(_memories);
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
    _dataChangeController.add(null);
  }
}
