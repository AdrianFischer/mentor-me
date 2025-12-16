import '../../models/models.dart';
import '../../models/ai_models.dart';

abstract class StorageRepository {
  Future<void> init();
  
  /// Loads all projects and their associated tasks.
  /// Any tasks not assigned to a project are returned in a special "Agent Tasks" project or separate list, 
  /// but typically we want to return the full hierarchy.
  Future<List<Project>> getAllProjects();

  Future<void> saveProject(Project project);
  Future<void> deleteProject(String projectId);

  Future<void> saveTask(Task task);
  Future<void> deleteTask(String taskId);

  /// Chat History
  Future<void> saveChatMessage(ChatMessage message, String mode);
  Future<List<ChatMessage>> getChatHistory(String mode);
  Future<void> clearChatHistory(String mode);

  /// Knowledge Base
  Future<void> saveKnowledge(Knowledge knowledge);
  Future<List<Knowledge>> getAllKnowledge();

  /// Stream that emits when data is changed externally or needs reload.
  Stream<void> get onDataChanged;
}
