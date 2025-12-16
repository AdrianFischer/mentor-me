import 'data_service.dart';

class DebugDataService {
  final DataService _dataService;

  DebugDataService(this._dataService);

  void seedComplexTree() {
    _dataService.clear();

    // Project Alpha
    String p1 = _dataService.addProject("Project Alpha");
    String t1 = _dataService.addTask(p1, "Task Alpha 1")!;
    _dataService.addSubtask(t1, "Subtask 1.1");
    _dataService.addSubtask(t1, "Subtask 1.2");
    _dataService.addTask(p1, "Task Alpha 2");

    // Project Beta
    String p2 = _dataService.addProject("Project Beta");
    _dataService.addTask(p2, "Task Beta 1");

    // Inbox
    String inbox = _dataService.addProject("Inbox");
    _dataService.addTask(inbox, "Check Emails");
  }
}




