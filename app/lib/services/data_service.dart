import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/ai_models.dart';
import 'project_service.dart';
import 'conversation_service.dart';
import 'memory_service.dart';
import 'knowledge_service.dart';
import 'agent_session_tracker.dart';

import '../data/repository/storage_repository.dart';

class DataService extends ChangeNotifier {

  factory DataService.withRepository(StorageRepository repository) {
    return DataService(
      ProjectService(repository),
      ConversationService(repository),
      MemoryService(repository),
      KnowledgeService(repository),
      AgentSessionTracker(),
    );
  }

  final ProjectService projectService;
  final ConversationService conversationService;
  final MemoryService memoryService;
  final KnowledgeService knowledgeService;
  final AgentSessionTracker sessionTracker;

  DataService(
    this.projectService,
    this.conversationService,
    this.memoryService,
    this.knowledgeService,
    this.sessionTracker,
  ) {
    projectService.addListener(notifyListeners);
    conversationService.addListener(notifyListeners);
    memoryService.addListener(notifyListeners);
    knowledgeService.addListener(notifyListeners);
    sessionTracker.addListener(notifyListeners);
  }
  
  List<Project> get projects => projectService.projects;
  List<Conversation> get conversations => conversationService.conversations;
  List<Memory> get memories => memoryService.memories;

  // --- Session Indexing ---
  void clearSessionIndex() => sessionTracker.clearSessionIndex();
  int addToSessionIndex(String id) => sessionTracker.addToSessionIndex(id);
  String? getIdFromSessionIndex(int index) => sessionTracker.getIdFromSessionIndex(index);

  // --- Local Image Artifacts ---
  Future<String> saveImageArtifact(Uint8List bytes, String filename) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    final baseDir = home != null ? '$home/.assisted_intelligence' : 'data';
    final imagesDir = Directory('$baseDir/artifacts/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final file = File('${imagesDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.absolute.path;
  }

  Future<void> addLocalImagePath(String itemId, String path) => projectService.addLocalImagePath(itemId, path);
  Future<void> removeLocalImagePath(String itemId, String path) => projectService.removeLocalImagePath(itemId, path);

  List<String> get allTags => projectService.allTags;
  List<TaggedItem> getItemsWithTag(String tag) => projectService.getItemsWithTag(tag);

  Future<String> addProject(String title) => projectService.addProject(title);
  Future<String> insertProject(String title, int index) => projectService.insertProject(title, index);
  
  Future<String?> addTask(String projectId, String title) => projectService.addTask(projectId, title);
  Future<String?> insertTask(String projectId, String title, int index) => projectService.insertTask(projectId, title, index);
  
  Future<String?> addSubtask(String taskId, String title) => projectService.addSubtask(taskId, title);
  Future<String?> insertSubtask(String taskId, String title, int index) => projectService.insertSubtask(taskId, title, index);

  void setTaskGoal(String taskId, TaskGoal goal) => projectService.setTaskGoal(taskId, goal);
  void recordGoalProgress(String taskId, {double? amount, bool? isSuccess, String? note}) => projectService.recordGoalProgress(taskId, amount: amount, isSuccess: isSuccess, note: note);

  void upsertProject(Project project) => projectService.upsertProject(project);
  void upsertTask(Task task) => projectService.upsertTask(task);
  void deleteItem(String itemId) => projectService.deleteItem(itemId);

  Future<void> setItemStatus(String itemId, bool isCompleted) => projectService.setItemStatus(itemId, isCompleted);
  Future<void> setAiStatus(String itemId, AiStatus status) => projectService.setAiStatus(itemId, status);

  void updateTitle(String itemId, String newTitle) => projectService.updateTitle(itemId, newTitle);
  void updateNotes(String itemId, String newNotes) => projectService.updateNotes(itemId, newNotes);

  void reorderProjects(int oldIndex, int newIndex) => projectService.reorderProjects(oldIndex, newIndex);
  void reorderTasks(String projectId, int oldIndex, int newIndex) => projectService.reorderTasks(projectId, oldIndex, newIndex);
  void reorderSubtasks(String taskId, int oldIndex, int newIndex) => projectService.reorderSubtasks(taskId, oldIndex, newIndex);

  // --- Long-term Memory ---
  Future<void> saveMemory(String fact) => memoryService.saveMemory(fact);
  Future<void> deleteMemory(String id) => memoryService.deleteMemory(id);

  // --- Conversations ---
  String createConversation(String title) => conversationService.createConversation(title);
  void updateConversationTitle(String id, String title) => conversationService.updateConversationTitle(id, title);
  void updateConversationNotes(String id, String notes) => conversationService.updateConversationNotes(id, notes);
  void deleteConversation(String id) => conversationService.deleteConversation(id);
  Future<void> saveChatMessage(ChatMessage message, String mode) => conversationService.saveChatMessage(message, mode);
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) => conversationService.getChatHistory(mode, conversationId: conversationId);
  Future<void> clearChatHistory(String mode, {String? conversationId}) => conversationService.clearChatHistory(mode, conversationId: conversationId);

  // --- Knowledge Base ---
  Future<void> saveKnowledge(String content) => knowledgeService.saveKnowledge(content);
  Future<void> updateKnowledge(Knowledge knowledge) => knowledgeService.updateKnowledge(knowledge);
  Future<void> deleteKnowledge(String id) => knowledgeService.deleteKnowledge(id);
  Future<List<Knowledge>> getAllKnowledge() => knowledgeService.getAllKnowledge();

  void clear() {
    projectService.clear();
    conversationService.clear();
  }

  Future<void> initData() async {
     await projectService.initData();
     await conversationService.initData();
     await memoryService.initData();
  }

  @override
  void dispose() {
    projectService.removeListener(notifyListeners);
    conversationService.removeListener(notifyListeners);
    memoryService.removeListener(notifyListeners);
    knowledgeService.removeListener(notifyListeners);
    sessionTracker.removeListener(notifyListeners);
    super.dispose();
  }
}
