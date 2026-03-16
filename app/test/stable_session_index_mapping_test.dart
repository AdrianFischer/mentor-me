import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/agent_session_tracker.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/services/conversation_service.dart';
import 'package:flutter_app/services/memory_service.dart';
import 'package:flutter_app/services/knowledge_service.dart';
import 'helpers/fake_storage_repository.dart';

void main() {
  test('Stable Session Index Mapping Test: UI index correctly maps to stable UUIDs', () async {
    final repo = FakeStorageRepository();
    final sessionTracker = AgentSessionTracker();
    final nodeService = NodeService(repo);
    final conversationService = ConversationService(repo);
    final memoryService = MemoryService(repo);
    final knowledgeService = KnowledgeService(repo);
    
    final dataService = DataService(
      nodeService,
      conversationService,
      memoryService,
      knowledgeService,
      sessionTracker,
    );

    // 1. Create a few tasks/projects. We get UUIDs back.
    final projId = await nodeService.addChild(null, "Project Alpha");
    expect(projId, isNotNull);
    
    final task1Id = await nodeService.addChild(projId, "Task 1");
    expect(task1Id, isNotNull);
    
    final task2Id = await nodeService.addChild(projId, "Task 2");
    expect(task2Id, isNotNull);
    
    // 2. Simulate AI or UI rendering "List Todos" and populating the Session Tracker.
    dataService.clearSessionIndex();
    final indexProj = dataService.addToSessionIndex(projId!);
    final indexTask1 = dataService.addToSessionIndex(task1Id!);
    final indexTask2 = dataService.addToSessionIndex(task2Id!);

    // Indices should be 1-based, sequential
    expect(indexProj, 1);
    expect(indexTask1, 2);
    expect(indexTask2, 3);

    // Re-adding returns the SAME stable index, without adding duplicates
    final repeatedIndexTask1 = dataService.addToSessionIndex(task1Id);
    expect(repeatedIndexTask1, 2);

    // 3. AI says "Update Task 2" using index 3.
    final targetId = dataService.getIdFromSessionIndex(3);
    expect(targetId, task2Id, reason: "Index 3 should map precisely to the second task's UUID");

    // Let's verify we can mutate the correct entity.
    nodeService.updateTitle(targetId!, "Task 2 - Completed");
    
    final updatedNode = nodeService.findNode(task2Id);
    expect(updatedNode?.title, "Task 2 - Completed", 
      reason: "The underlying node should be updated using its mapped UUID");
    
    final unmutatedTask = nodeService.findNode(task1Id);
    expect(unmutatedTask?.title, "Task 1", 
      reason: "Other nodes should be unaffected");

    // 4. Invalid indices bounds
    expect(dataService.getIdFromSessionIndex(0), isNull);
    expect(dataService.getIdFromSessionIndex(4), isNull);
    
    // 5. Clearing index mapping works
    dataService.clearSessionIndex();
    expect(dataService.getIdFromSessionIndex(1), isNull, 
      reason: "Indices should map to null after clearing the session index");
  });
}
