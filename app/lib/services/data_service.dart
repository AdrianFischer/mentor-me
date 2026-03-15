import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ai_models.dart';
import 'node_service.dart';
import 'conversation_service.dart';
import 'memory_service.dart';
import 'knowledge_service.dart';
import 'agent_session_tracker.dart';

class DataService extends ChangeNotifier {

  final NodeService nodeService;
  final ConversationService conversationService;
  final MemoryService memoryService;
  final KnowledgeService knowledgeService;
  final AgentSessionTracker sessionTracker;

  DataService(
    this.nodeService,
    this.conversationService,
    this.memoryService,
    this.knowledgeService,
    this.sessionTracker,
  ) {
    nodeService.addListener(notifyListeners);
    conversationService.addListener(notifyListeners);
    memoryService.addListener(notifyListeners);
    knowledgeService.addListener(notifyListeners);
    sessionTracker.addListener(notifyListeners);
  }

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
    nodeService.clear();
    conversationService.clear();
  }

  Future<void> initData() async {
     await nodeService.initData();
     await conversationService.initData();
     await memoryService.initData();
  }

  @override
  void dispose() {
    nodeService.removeListener(notifyListeners);
    conversationService.removeListener(notifyListeners);
    memoryService.removeListener(notifyListeners);
    knowledgeService.removeListener(notifyListeners);
    sessionTracker.removeListener(notifyListeners);
    super.dispose();
  }
}
