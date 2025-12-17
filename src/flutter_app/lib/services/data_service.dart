import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/ai_models.dart';
import '../data/repository/storage_repository.dart';
import 'markdown_persistence_service.dart';

const uuid = Uuid();

class DataService extends ChangeNotifier {
  final StorageRepository _repository;
  final MarkdownPersistenceService _markdownPersistence;
  final List<Project> _projects = [];
  final Map<String, Timer> _debounceTimers = {};

  DataService(this._repository, this._markdownPersistence);

  List<Project> get projects => _projects;

  // --- AI / UI Tool Interface ---

  String addProject(String title) {
    print("[VERIFY_FLOW] Data Update: addProject($title)");
    // Determine order: Last + 1.0
    double newOrder = 0.0;
    if (_projects.isNotEmpty) {
      // Assuming _projects is sorted by order
      newOrder = _projects.last.order + 1.0;
    }
    
    final project = Project(id: uuid.v4(), title: title, order: newOrder);
    _projects.add(project);
    notifyListeners();
    _repository.saveProject(project);
    return project.id;
  }

  String? addTask(String projectId, String title) {
    try {
      print("[VERIFY_FLOW] Data Update: addTask($title) to $projectId");
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index == -1) return null;

      final project = _projects[index];
      
      double newOrder = 0.0;
      if (project.tasks.isNotEmpty) {
        newOrder = project.tasks.last.order + 1.0;
      }
      
      final task = Task(id: uuid.v4(), title: title, projectId: projectId, order: newOrder);
      
      final newTasks = List<Task>.from(project.tasks)..add(task);
      final newProject = project.copyWith(tasks: newTasks);
      
      _projects[index] = newProject;
      notifyListeners();
      
      _repository.saveTask(task);
      _markdownPersistence.saveTask(task, newProject);

      return task.id;
    } catch (e) {
      debugPrint('Error adding task: $e');
      return null;
    }
  }

  String? addSubtask(String taskId, String title) {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final taskIndex = project.tasks.indexWhere((t) => t.id == taskId);
      
      if (taskIndex != -1) {
        final task = project.tasks[taskIndex];
        
        double newOrder = 0.0;
        if (task.subtasks.isNotEmpty) {
          newOrder = task.subtasks.last.order + 1.0;
        }

        final subtask = Subtask(id: uuid.v4(), title: title, order: newOrder);
        
        final newSubtasks = List<Subtask>.from(task.subtasks)..add(subtask);
        final newTask = task.copyWith(subtasks: newSubtasks);
        
        final newTasksList = List<Task>.from(project.tasks);
        newTasksList[taskIndex] = newTask;
        
        final newProject = project.copyWith(tasks: newTasksList);
        _projects[i] = newProject;
        
        notifyListeners();
        
        _repository.saveTask(newTask);
        
        return subtask.id;
      }
    }
    return null;
  }

  void deleteItem(String itemId) {
    // Check if it is a Project
    int projectIndex = _projects.indexWhere((p) => p.id == itemId);
    if (projectIndex != -1) {
       _projects.removeAt(projectIndex);
       _repository.deleteProject(itemId);
       notifyListeners();
       return;
    }
    
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      // Check if it is a Task
      final taskIndex = project.tasks.indexWhere((t) => t.id == itemId);
      if (taskIndex != -1) {
        final task = project.tasks[taskIndex];
        
        final newTasks = List<Task>.from(project.tasks)..removeAt(taskIndex);
        final newProject = project.copyWith(tasks: newTasks);
        _projects[i] = newProject;
        
        _repository.deleteTask(task.id);
        notifyListeners();
        return;
      }
      
      // Check if it is a Subtask
      for (var j = 0; j < project.tasks.length; j++) {
        final task = project.tasks[j];
        final subIndex = task.subtasks.indexWhere((s) => s.id == itemId);
        
        if (subIndex != -1) {
           final newSubtasks = List<Subtask>.from(task.subtasks)..removeAt(subIndex);
           final newTask = task.copyWith(subtasks: newSubtasks);
           
           final newTasksList = List<Task>.from(project.tasks);
           newTasksList[j] = newTask;
           
           final newProject = project.copyWith(tasks: newTasksList);
           _projects[i] = newProject;
           
           _repository.saveTask(newTask);
           notifyListeners();
           return;
        }
      }
    }
  }

  void setItemStatus(String itemId, bool isCompleted) {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      for (var j = 0; j < project.tasks.length; j++) {
        final task = project.tasks[j];
        
        if (task.id == itemId) {
          final newTask = task.copyWith(isCompleted: isCompleted);
          final newTasksList = List<Task>.from(project.tasks);
          newTasksList[j] = newTask;
          
          final newProject = project.copyWith(tasks: newTasksList);
          _projects[i] = newProject;
          
          _repository.saveTask(newTask);
          notifyListeners();
          return;
        }
        
        for (var k = 0; k < task.subtasks.length; k++) {
          final subtask = task.subtasks[k];
          if (subtask.id == itemId) {
            final newSubtask = subtask.copyWith(isCompleted: isCompleted);
            final newSubtasks = List<Subtask>.from(task.subtasks);
            newSubtasks[k] = newSubtask;
            
            final newTask = task.copyWith(subtasks: newSubtasks);
            final newTasksList = List<Task>.from(project.tasks);
            newTasksList[j] = newTask;
            
            final newProject = project.copyWith(tasks: newTasksList);
            _projects[i] = newProject;
            
            _repository.saveTask(newTask);
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  void updateTitle(String itemId, String newTitle) {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      
      if (project.id == itemId) {
        final newProject = project.copyWith(title: newTitle);
        _projects[i] = newProject;
        notifyListeners();
        _repository.saveProject(newProject);
        return;
      }
      
      for (var j = 0; j < project.tasks.length; j++) {
        final task = project.tasks[j];
        
        if (task.id == itemId) {
          final newTask = task.copyWith(title: newTitle);
          final newTasksList = List<Task>.from(project.tasks);
          newTasksList[j] = newTask;
          
          final newProject = project.copyWith(tasks: newTasksList);
          _projects[i] = newProject;
          
          notifyListeners();
          _debounceSave(newTask);
          return;
        }
        
        for (var k = 0; k < task.subtasks.length; k++) {
          final subtask = task.subtasks[k];
          
          if (subtask.id == itemId) {
            final newSubtask = subtask.copyWith(title: newTitle);
            final newSubtasks = List<Subtask>.from(task.subtasks);
            newSubtasks[k] = newSubtask;
            
            final newTask = task.copyWith(subtasks: newSubtasks);
            final newTasksList = List<Task>.from(project.tasks);
            newTasksList[j] = newTask;
            
            final newProject = project.copyWith(tasks: newTasksList);
            _projects[i] = newProject;
            
            notifyListeners();
            _debounceSave(newTask);
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
      _repository.saveTask(task);
      _debounceTimers.remove(task.id);
    });
  }
  
  Future<void> initData() async {
    await _repository.init();
    
    // Listen for file changes (hot reload)
    _repository.onDataChanged.listen((_) {
      print("Data change detected. Reloading...");
      _reloadProjects();
    });
    
    await _reloadProjects();
  }
  
  Future<void> _reloadProjects() async {
    final projects = await _repository.getAllProjects();
    _projects.clear();
    _projects.addAll(projects);
    notifyListeners();
  }

  // --- Reordering ---

  void reorderProjects(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _projects.removeAt(oldIndex);
    _projects.insert(newIndex, item);
    
    // Recalculate order
    for (int i = 0; i < _projects.length; i++) {
        _projects[i] = _projects[i].copyWith(order: i.toDouble());
        _repository.saveProject(_projects[i]);
    }

    notifyListeners();
  }

  void reorderTasks(String projectId, int oldIndex, int newIndex) {
    final pIndex = _projects.indexWhere((p) => p.id == projectId);
    if (pIndex == -1) return;

    final project = _projects[pIndex];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final newTasks = List<Task>.from(project.tasks);
    final item = newTasks.removeAt(oldIndex);
    newTasks.insert(newIndex, item);

    // Recalculate order
    for (int i = 0; i < newTasks.length; i++) {
        newTasks[i] = newTasks[i].copyWith(order: i.toDouble());
        _repository.saveTask(newTasks[i]);
    }

    final newProject = project.copyWith(tasks: newTasks);
    _projects[pIndex] = newProject;
    notifyListeners();
  }

  void reorderSubtasks(String taskId, int oldIndex, int newIndex) {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final tIndex = project.tasks.indexWhere((t) => t.id == taskId);
      
      if (tIndex != -1) {
        final task = project.tasks[tIndex];
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        
        final newSubtasks = List<Subtask>.from(task.subtasks);
        final item = newSubtasks.removeAt(oldIndex);
        newSubtasks.insert(newIndex, item);
        
        // Recalculate order
        for (int j = 0; j < newSubtasks.length; j++) {
            newSubtasks[j] = newSubtasks[j].copyWith(order: j.toDouble());
        }

        final newTask = task.copyWith(subtasks: newSubtasks);
        final newTasks = List<Task>.from(project.tasks);
        newTasks[tIndex] = newTask;
        
        final newProject = project.copyWith(tasks: newTasks);
        _projects[i] = newProject;
        
        notifyListeners();
        _repository.saveTask(newTask);
        return;
      }
    }
  }

  // --- Chat Persistence ---

  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    await _repository.saveChatMessage(message, mode);
  }

  Future<List<ChatMessage>> getChatHistory(String mode) async {
    return _repository.getChatHistory(mode);
  }

  Future<void> clearChatHistory(String mode) async {
    await _repository.clearChatHistory(mode);
  }

  // --- Knowledge Base ---

  Future<void> saveKnowledge(String content) async {
    print("[VERIFY_FLOW] Saving knowledge: $content");
    final knowledge = Knowledge(content: content);
    await _repository.saveKnowledge(knowledge);
  }

  Future<List<Knowledge>> getAllKnowledge() async {
    return _repository.getAllKnowledge();
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