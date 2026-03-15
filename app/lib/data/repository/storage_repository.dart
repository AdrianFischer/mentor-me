import '../../models/node.dart';
import '../../models/ai_models.dart';

abstract class StorageRepository {
  Future<void> init();

  /// Loads all root-level nodes.
  Future<List<Node>> getAllNodes();

  Future<void> saveNode(Node node);
  Future<void> deleteNode(String nodeId);

  /// Chat History & Conversations
  Future<void> saveConversation(Conversation conversation);
  Future<List<Conversation>> getAllConversations();
  Future<void> deleteConversation(String conversationId);

  Future<void> saveChatMessage(ChatMessage message, String mode);
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId});
  Future<void> clearChatHistory(String mode, {String? conversationId});

  /// Knowledge Base
  Future<void> saveKnowledge(Knowledge knowledge);
  Future<List<Knowledge>> getAllKnowledge();
  Future<void> deleteKnowledge(String id);

  /// Long-term Memory
  Future<void> saveMemory(Memory memory);
  Future<List<Memory>> getAllMemories();
  Future<void> deleteMemory(String id);

  /// Stream that emits when data is changed externally or needs reload.
  Stream<void> get onDataChanged;
}
