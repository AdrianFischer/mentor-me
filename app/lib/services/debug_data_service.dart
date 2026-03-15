import 'node_service.dart';

class DebugDataService {
  final NodeService _nodeService;

  DebugDataService(this._nodeService);

  Future<void> seedComplexTree() async {
    _nodeService.clear();

    // Project Alpha
    String? p1 = await _nodeService.addChild(null, "Project Alpha");
    String? t1 = await _nodeService.addChild(p1, "Task Alpha 1");
    if (t1 != null) {
      await _nodeService.addChild(t1, "Subtask 1.1");
      await _nodeService.addChild(t1, "Subtask 1.2");
    }
    await _nodeService.addChild(p1, "Task Alpha 2");

    // Project Beta
    String? p2 = await _nodeService.addChild(null, "Project Beta");
    await _nodeService.addChild(p2, "Task Beta 1");

    // Inbox
    String? inbox = await _nodeService.addChild(null, "Inbox");
    await _nodeService.addChild(inbox, "Check Emails");
  }
}
