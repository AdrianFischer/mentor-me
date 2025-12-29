import '../../models/models.dart';
import '../../models/ai_models.dart';

abstract class StorageRepository {
  Future<void> init();
  
  /// Loads all projects and their associated tasks.
  Future<List<Project>> getAllProjects();

  Future<void> saveProject(Project project);
  Future<void> deleteProject(String projectId);

  Future<void> saveTask(Task task);
  Future<void> deleteTask(String taskId);

  /// Chat History & Conversations
  Future<void> saveConversation(Conversation conversation);
  Future<List<Conversation>> getAllConversations();
  Future<void> deleteConversation(String conversationId);

  Future<void> saveChatMessage(ChatMessage message, String mode);
  /// If conversationId is provided, returns messages for that conversation.
  /// If not, assumes legacy/global mode behavior.
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId});
  Future<void> clearChatHistory(String mode, {String? conversationId});

  /// Knowledge Base
  Future<void> saveKnowledge(Knowledge knowledge);
  Future<List<Knowledge>> getAllKnowledge();
  Future<void> deleteKnowledge(String id);

  /// Stream that emits when data is changed externally or needs reload.
  Stream<void> get onDataChanged;
}