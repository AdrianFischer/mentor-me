import 'data_service.dart';

class DebugDataService {
  final DataService _dataService;

  DebugDataService(this._dataService);

  Future<void> seedComplexTree() async {
    _dataService.clear();

    // Project Alpha
    String p1 = await _dataService.addProject("Project Alpha");
    String? t1 = await _dataService.addTask(p1, "Task Alpha 1");
    if (t1 != null) {
      await _dataService.addSubtask(t1, "Subtask 1.1");
      await _dataService.addSubtask(t1, "Subtask 1.2");
    }
    await _dataService.addTask(p1, "Task Alpha 2");

    // Project Beta
    String p2 = await _dataService.addProject("Project Beta");
    await _dataService.addTask(p2, "Task Beta 1");

    // Inbox
    String inbox = await _dataService.addProject("Inbox");
    await _dataService.addTask(inbox, "Check Emails");
  }
}




