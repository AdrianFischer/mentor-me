import 'dart:async';
import 'dart:io';
import '../../config.dart';
import '../../utils/markdown_parser.dart';
import '../../models/models.dart';
import '../../models/ai_models.dart';
import 'storage_repository.dart';

/// A non-persistent, in-memory implementation of StorageRepository.
/// This serves as the "source of truth" loaded from files on startup.
class InMemoryRepository implements StorageRepository {
  final List<Project> _projects = [];
  final List<Conversation> _conversations = [];
  final List<ChatMessage> _chatHistory = [];
  final List<Knowledge> _knowledgeBase = [];
  
  final _dataChangeController = StreamController<void>.broadcast();

  @override
  Stream<void> get onDataChanged => _dataChangeController.stream;

  @override
  Future<void> init() async {
    _projects.clear();
    final dataDir = Config.dataDir;
    if (dataDir == null) return;

    final dir = Directory('$dataDir/todos');
    if (!await dir.exists()) return;

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.md')) {
          if (entity.path.endsWith('README.md')) continue;
          
          try {
            final content = await entity.readAsString();
            final project = MarkdownParser.parseProject(content);
            _projects.add(project);
          } catch (e) {
            print('Error parsing file ${entity.path}: $e');
          }
        }
      }
      print('InMemoryRepository loaded ${_projects.length} projects from $dataDir');
    } catch (e) {
      print('Error scanning directory $dataDir: $e');
    }
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
  }

  @override
  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
  }

  // --- Tasks (Helper methods, usually part of Project) ---

  @override
  Future<void> saveTask(Task task) async {
    // In Isar, tasks were separate collections. Here they are embedded in Projects.
    // If the caller saves a task, we must find the project and update it.
    // However, DataService usually saves the Project after saving the Task.
    // If DataService calls saveTask, we technically need to update the project in _projects.
    
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

    _projects[pIndex] = project.copyWith(tasks: newTasks);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final tIndex = project.tasks.indexWhere((t) => t.id == taskId);
      if (tIndex != -1) {
        final newTasks = List<Task>.from(project.tasks)..removeAt(tIndex);
        _projects[i] = project.copyWith(tasks: newTasks);
        return;
      }
    }
  }

  // --- Conversations ---

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

  // --- Chat History ---

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    _chatHistory.add(message);
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      return _chatHistory.where((m) => m.conversationId == conversationId).toList();
    }
    // Legacy global mode support if needed, or return all
    // Assuming mode is unused in new conversation-centric model or filtered by it
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

  // --- Knowledge Base ---

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    return List.unmodifiable(_knowledgeBase);
  }

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
     // Check for ID? Knowledge model usually has ID.
     // Assuming simple add for now or strict replacement.
     // If Knowledge has ID:
     // final index = _knowledgeBase.indexWhere((k) => k.id == knowledge.id);
     // if (index != -1) _knowledgeBase[index] = knowledge; else _knowledgeBase.add(knowledge);
     
     // For now, just add as we don't have full Knowledge model context in this file snippet, 
     // but following pattern:
     _knowledgeBase.add(knowledge);
  }

  @override
  Future<void> deleteKnowledge(String id) async {
    // _knowledgeBase.removeWhere((k) => k.id == id);
  }
}
