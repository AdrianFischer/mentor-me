import 'dart:async';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';

class FakeStorageRepository implements StorageRepository {
  List<Project> _projects;
  final List<Conversation> _conversations = [];
  final List<ChatMessage> _messages = [];
  final List<Knowledge> _knowledge = [];
  final _controller = StreamController<void>.broadcast();
  
  FakeStorageRepository({List<Project>? initialProjects}) 
      : _projects = initialProjects ?? [];

  @override
  List<Project> getProjects() => _projects;

  @override
  Future<void> saveProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    _controller.add(null);
  }

  @override
  Future<void> saveTask(Task task) async {
    if (task.projectId == null) return;
    final pIndex = _projects.indexWhere((p) => p.id == task.projectId);
    if (pIndex != -1) {
      final project = _projects[pIndex];
      final tIndex = project.tasks.indexWhere((t) => t.id == task.id);
      
      List<Task> newTasks;
      if (tIndex != -1) {
        newTasks = List<Task>.from(project.tasks);
        newTasks[tIndex] = task;
      } else {
        newTasks = List<Task>.from(project.tasks)..add(task);
      }
      _projects[pIndex] = project.copyWith(tasks: newTasks);
      _controller.add(null);
    }
  }

  @override
  Future<void> updateTitle(String id, String newTitle) async {
    // Basic implementation for testing if needed
  }

  @override
  Future<void> setItemStatus(String id, bool isCompleted) async {
    for (var i = 0; i < _projects.length; i++) {
      var project = _projects[i];
      // Check Tasks
      int tIndex = project.tasks.indexWhere((t) => t.id == id);
      if (tIndex != -1) {
        var task = project.tasks[tIndex];
        var newTask = task.copyWith(isCompleted: isCompleted);
        var newTasks = List<Task>.from(project.tasks);
        newTasks[tIndex] = newTask;
        _projects[i] = project.copyWith(tasks: newTasks);
        _controller.add(null);
        return;
      }
      
      // Check Subtasks
      for (var j = 0; j < project.tasks.length; j++) {
        var task = project.tasks[j];
        int sIndex = task.subtasks.indexWhere((s) => s.id == id);
        if (sIndex != -1) {
           var subtask = task.subtasks[sIndex];
           var newSubtask = subtask.copyWith(isCompleted: isCompleted);
           var newSubtasks = List<Subtask>.from(task.subtasks);
           newSubtasks[sIndex] = newSubtask;
           var newTask = task.copyWith(subtasks: newSubtasks);
           var newTasks = List<Task>.from(project.tasks);
           newTasks[j] = newTask;
           _projects[i] = project.copyWith(tasks: newTasks);
           _controller.add(null);
           return;
        }
      }
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    // Try delete project
    int pIndex = _projects.indexWhere((p) => p.id == id);
    if (pIndex != -1) {
      _projects.removeAt(pIndex);
      _controller.add(null);
      return;
    }
    
    // Try delete task
    for (var i = 0; i < _projects.length; i++) {
      var project = _projects[i];
      int tIndex = project.tasks.indexWhere((t) => t.id == id);
      if (tIndex != -1) {
        var newTasks = List<Task>.from(project.tasks)..removeAt(tIndex);
        _projects[i] = project.copyWith(tasks: newTasks);
        _controller.add(null);
        return;
      }
      
      // Try delete subtask
      for (var j = 0; j < project.tasks.length; j++) {
        var task = project.tasks[j];
        int sIndex = task.subtasks.indexWhere((s) => s.id == id);
        if (sIndex != -1) {
           var newSubtasks = List<Subtask>.from(task.subtasks)..removeAt(sIndex);
           var newTask = task.copyWith(subtasks: newSubtasks);
           var newTasks = List<Task>.from(project.tasks);
           newTasks[j] = newTask;
           _projects[i] = project.copyWith(tasks: newTasks);
           _controller.add(null);
           return;
        }
      }
    }
  }

  @override
  Future<void> reorderProjects(int oldIndex, int newIndex) async {}
  @override
  Future<void> reorderTasks(String projectId, int oldIndex, int newIndex) async {}
  @override
  Future<void> reorderSubtasks(String taskId, int oldIndex, int newIndex) async {}
  
  @override
  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    _controller.add(null);
  }

  @override
  Future<void> deleteTask(String taskId) async {
     // Implement if needed for specific tests
  }

  // --- Chat History ---

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
    return _conversations;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messages.removeWhere((m) => m.conversationId == conversationId);
  }

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    _messages.add(message);
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      return _messages.where((m) => m.conversationId == conversationId).toList();
    }
    // Legacy behavior or default
    return _messages;
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      _messages.removeWhere((m) => m.conversationId == conversationId);
    } else {
      _messages.clear();
    }
  }

  // --- Knowledge ---

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
    final index = _knowledge.indexWhere((k) => k.id == knowledge.id);
    if (index >= 0) {
      _knowledge[index] = knowledge;
    } else {
      _knowledge.add(knowledge);
    }
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    return _knowledge;
  }

  @override
  Future<void> deleteKnowledge(String id) async {
    _knowledge.removeWhere((k) => k.id == id);
  }

  @override
  Future<List<Project>> getAllProjects() async => _projects;
  
  @override
  Future<void> init() async {}
  
  @override
  Stream<void> get onDataChanged => _controller.stream;
}
