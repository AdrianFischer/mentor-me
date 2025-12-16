import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'markdown_persistence_service.dart';

class DataService extends ChangeNotifier {
  final List<Project> _projects = [];
  final MarkdownPersistenceService _persistence = MarkdownPersistenceService();
  final Map<String, Timer> _debounceTimers = {};

  List<Project> get projects => _projects;

  // --- AI / UI Tool Interface ---

  String addProject(String title) {
    print("[VERIFY_FLOW] Data Update: addProject($title)");
    final project = Project(title: title);
    _projects.add(project);
    notifyListeners();
    return project.id;
  }

  String? addTask(String projectId, String title) {
    try {
      print("[VERIFY_FLOW] Data Update: addTask($title) to $projectId");
      final project = _projects.firstWhere((p) => p.id == projectId);
      final task = Task(title: title);
      project.tasks.add(task);
      notifyListeners();
      
      _persistence.saveTask(task);

      return task.id;
    } catch (e) {
      debugPrint('Error adding task: $e');
      return null;
    }
  }

  String? addSubtask(String taskId, String title) {
    for (var project in _projects) {
      for (var task in project.tasks) {
        if (task.id == taskId) {
          final subtask = Subtask(title: title);
          task.subtasks.add(subtask);
          notifyListeners();
          
          _persistence.saveTask(task);
          
          return subtask.id;
        }
      }
    }
    return null;
  }

  void deleteItem(String itemId) {
    // Check if it is a Project (local only for now?)
    _projects.removeWhere((p) => p.id == itemId);
    
    for (var project in _projects) {
      // Check if it is a Task
      final taskIndex = project.tasks.indexWhere((t) => t.id == itemId);
      if (taskIndex != -1) {
        final task = project.tasks[taskIndex];
        project.tasks.removeAt(taskIndex);
        _persistence.deleteTask(task.id);
      }
      
      // Check if it is a Subtask
      for (var task in project.tasks) {
        final subIndex = task.subtasks.indexWhere((s) => s.id == itemId);
        if (subIndex != -1) {
           task.subtasks.removeAt(subIndex);
           _persistence.saveTask(task);
        }
      }
    }
    notifyListeners();
  }

  void setItemStatus(String itemId, bool isCompleted) {
    for (var project in _projects) {
      for (var task in project.tasks) {
        if (task.id == itemId) {
          task.isCompleted = isCompleted;
          notifyListeners();
          _persistence.saveTask(task);
          return;
        }
        for (var subtask in task.subtasks) {
          if (subtask.id == itemId) {
            subtask.isCompleted = isCompleted;
            notifyListeners();
             _persistence.saveTask(task);
            return;
          }
        }
      }
    }
  }

  void updateTitle(String itemId, String newTitle) {
    for (var project in _projects) {
      if (project.id == itemId) {
        project.title = newTitle;
        notifyListeners();
        // Projects are not persisted to file individually yet in this design
        return;
      }
      for (var task in project.tasks) {
        if (task.id == itemId) {
          task.title = newTitle;
          notifyListeners();
          _debounceSave(task);
          return;
        }
        for (var subtask in task.subtasks) {
          if (subtask.id == itemId) {
            subtask.title = newTitle;
            notifyListeners();
            _debounceSave(task);
            return;
          }
        }
      }
    }
  }
  
  void _debounceSave(Task task) {
    if (_debounceTimers.containsKey(task.id)) {
      _debounceTimers[task.id]!.cancel();
    }
    _debounceTimers[task.id] = Timer(const Duration(milliseconds: 1000), () {
      _persistence.saveTask(task);
      _debounceTimers.remove(task.id);
    });
  }
  
  Future<void> initData() async {
    await _persistence.init();
    
    // Listen for file changes (hot reload)
    _persistence.onDataChanged.listen((_) {
      print("File change detected. Reloading data...");
      _reloadTasks();
    });
    
    await _reloadTasks();
  }
  
  Future<void> _reloadTasks() async {
    final tasks = await _persistence.loadTasks();
    
    _projects.clear();
    
    if (tasks.isNotEmpty) {
      // Use stable ID for the Agent Project so selection persists
      _projects.add(Project(id: "agent_tasks_project", title: "Agent Tasks", tasks: tasks));
    }
    
    notifyListeners();
  }

  void clear() {
    _projects.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
