import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/models/node.dart';
import 'helpers/fake_storage_repository.dart';

class SpyingStorageRepository extends FakeStorageRepository {
  int saveNodeCallCount = 0;

  @override
  Future<void> saveNode(Node node) async {
    saveNodeCallCount++;
    await super.saveNode(node);
  }
}

void main() {
  test('Local-First Write-Behind Queue Test: debounces rapid updates', () async {
    final repo = SpyingStorageRepository();
    final nodeService = NodeService(repo);
    
    // Add a root node. This calls _addRootNode -> _persistRootList -> saveNode.
    final id = await nodeService.addChild(null, "Initial Task");
    expect(id, isNotNull);
    
    final initialSaveCount = repo.saveNodeCallCount;
    expect(initialSaveCount, 1);

    // Now perform rapid successive updates.
    // In node_service.dart, updateTitle calls _debounceSaveRoot with a 1000ms delay.
    nodeService.updateTitle(id!, "Task 1");
    nodeService.updateTitle(id, "Task 12");
    nodeService.updateTitle(id, "Task 123");
    
    // The debounce timer is running. saveNode should NOT be called yet.
    expect(repo.saveNodeCallCount, initialSaveCount, 
      reason: 'saveNode should be debounced during rapid updates');
    
    // Wait for the debounce duration (1000ms + buffer).
    await Future.delayed(const Duration(milliseconds: 1100));
    
    // After debounce, saveNode should be called exactly once for the final update.
    expect(repo.saveNodeCallCount, initialSaveCount + 1, 
      reason: 'saveNode should have been called exactly once after debounce timer completed');
    
    // Let's do another batch of updates to notes
    nodeService.updateNotes(id, "A");
    nodeService.updateNotes(id, "AB");
    nodeService.updateNotes(id, "ABC");
    
    expect(repo.saveNodeCallCount, initialSaveCount + 1, 
      reason: 'saveNode should be debounced during notes updates');
    
    await Future.delayed(const Duration(milliseconds: 1100));
    
    expect(repo.saveNodeCallCount, initialSaveCount + 2,
      reason: 'saveNode should have been called again after second debounce timer completed');
  });
}
