import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/ai_models.dart';
import '../data/repository/storage_repository.dart';
import 'markdown_persistence_service.dart';
import 'markdown_watcher_service.dart';

const uuid = Uuid();

class TaggedItem {
  final String id;
  final String title;
  final String type; // 'project', 'task', 'subtask'
  final dynamic originalObject;
  
  TaggedItem(this.id, this.title, this.type, this.originalObject);
}

class DataService extends ChangeNotifier {
  final StorageRepository _repository;
  final MarkdownPersistenceService _markdownPersistence;
  MarkdownWatcherService? _markdownWatcher;
  List<Project> _projects = [];
  final Map<String, Timer> _debounceTimers = {};
  
  // Conversations Cache
  List<Conversation> _conversations = [];

  DataService(this._repository, this._markdownPersistence);

  void setWatcher(MarkdownWatcherService watcher) {
    _markdownWatcher = watcher;
  }

  List<Project> get projects => _projects;
  List<Conversation> get conversations => _conversations;

  List<String> get allTags {
    final tags = <String>{};
    for (final p in _projects) {
      tags.addAll(p.tags);
      for (final t in p.tasks) {
        tags.addAll(t.tags);
        for (final s in t.subtasks) {
          tags.addAll(s.tags);
        }
      }
    }
    return tags.toList()..sort();
  }

  List<TaggedItem> getItemsWithTag(String tag) {
    final items = <TaggedItem>[];
    for (final p in _projects) {
      if (p.tags.contains(tag)) {
        items.add(TaggedItem(p.id, p.title, 'project', p));
      }
      for (final t in p.tasks) {
        if (t.tags.contains(tag)) {
          items.add(TaggedItem(t.id, t.title, 'task', t));
        }
        for (final s in t.subtasks) {
           if (s.tags.contains(tag)) {
             items.add(TaggedItem(s.id, s.title, 'subtask', s));
           }
        }
      }
    }
    return items;
  }

  List<String> _extractTags(String text) {
    final regex = RegExp(r'#[\w\u00C0-\u017F-]+');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  // --- AI / UI Tool Interface ---

  Future<void> _saveToMarkdown(Project project) async {
    _markdownWatcher?.recordSelfWrite();
    await _markdownPersistence.saveProject(project);
  }

  Future<String> addProject(String title) async {
    return insertProject(title, _projects.length);
  }

  Future<String> insertProject(String title, int index) async {
    print("[VERIFY_FLOW] Data Update: insertProject($title) at $index");
    
    final tags = _extractTags(title);
    final project = Project(id: uuid.v4(), title: title, order: index.toDouble(), tags: tags);
    
    if (_projects is! List<Project>) {
      _projects = List.from(_projects);
    }
    
    if (index >= _projects.length) {
      _projects.add(project);
    } else {
      _projects.insert(index, project);
    }

    final updatedProjects = List<Project>.from(_projects);

    // Update orders for all projects and save
    for (int i = 0; i < updatedProjects.length; i++) {
      updatedProjects[i] = updatedProjects[i].copyWith(order: i.toDouble());
      await _repository.saveProject(updatedProjects[i]);
    }

    notifyListeners();
    // await _repository.saveProject(project); // Already saved in loop
    await _saveToMarkdown(project);
    return project.id;
  }

  Future<String?> addTask(String projectId, String title) async {
    final pIndex = _projects.indexWhere((p) => p.id == projectId);
    if (pIndex == -1) return null;
    return insertTask(projectId, title, _projects[pIndex].tasks.length);
  }

  Future<String?> insertTask(String projectId, String title, int index) async {
    try {
      print("[VERIFY_FLOW] Data Update: insertTask($title) to $projectId at $index");
      final pIndex = _projects.indexWhere((p) => p.id == projectId);
      if (pIndex == -1) return null;

      final project = _projects[pIndex];
      final tags = _extractTags(title);
      final task = Task(id: uuid.v4(), title: title, projectId: projectId, order: index.toDouble(), tags: tags);
      
      final newTasks = List<Task>.from(project.tasks);
      if (index >= newTasks.length) {
        newTasks.add(task);
      } else {
        newTasks.insert(index, task);
      }

      // Update orders
      for (int i = 0; i < newTasks.length; i++) {
        newTasks[i] = newTasks[i].copyWith(order: i.toDouble());
        await _repository.saveTask(newTasks[i]);
      }

      final newProject = project.copyWith(tasks: newTasks);
      
      if (_projects is! List<Project>) {
        _projects = List.from(_projects);
      }
      _projects[pIndex] = newProject;
      notifyListeners();
      
      // await _repository.saveTask(task); // Saved in loop
      await _saveToMarkdown(newProject);

      return task.id;
    } catch (e) {
      debugPrint('Error inserting task: $e');
      return null;
    }
  }

  Future<String?> addSubtask(String taskId, String title) async {
    // Find task index and project
    for (var i = 0; i < _projects.length; i++) {
      final taskIndex = _projects[i].tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        return insertSubtask(taskId, title, _projects[i].tasks[taskIndex].subtasks.length);
      }
    }
    return null;
  }

  Future<String?> insertSubtask(String taskId, String title, int index) async {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final taskIndex = project.tasks.indexWhere((t) => t.id == taskId);
      
      if (taskIndex != -1) {
        final task = project.tasks[taskIndex];
        final tags = _extractTags(title);
        final subtask = Subtask(id: uuid.v4(), title: title, order: index.toDouble(), tags: tags);
        
        final newSubtasks = List<Subtask>.from(task.subtasks);
        if (index >= newSubtasks.length) {
          newSubtasks.add(subtask);
        } else {
          newSubtasks.insert(index, subtask);
        }

        // Update orders
        for (int j = 0; j < newSubtasks.length; j++) {
           newSubtasks[j] = newSubtasks[j].copyWith(order: j.toDouble());
        }

        final newTask = task.copyWith(subtasks: newSubtasks);
        final newTasksList = List<Task>.from(project.tasks);
        newTasksList[taskIndex] = newTask;
        
        final newProject = project.copyWith(tasks: newTasksList);
        _projects[i] = newProject;
        
        notifyListeners();
        
        await _repository.saveTask(newTask); // Helper saves whole task?
        await _saveToMarkdown(newProject);
        
        return subtask.id;
      }
    }
    return null;
  }

  void setTaskGoal(String taskId, TaskGoal goal) {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final taskIndex = project.tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        final task = project.tasks[taskIndex];
        final newTask = task.copyWith(goal: goal);
        
        final newTasksList = List<Task>.from(project.tasks);
        newTasksList[taskIndex] = newTask;
        
        final newProject = project.copyWith(tasks: newTasksList);
        _projects[i] = newProject;
        
        notifyListeners();
        _repository.saveTask(newTask);
        _markdownPersistence.saveProject(newProject);
        return;
      }
    }
  }

  void recordGoalProgress(String taskId, {double? amount, bool? isSuccess, String? note}) {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final taskIndex = project.tasks.indexWhere((t) => t.id == taskId);
      
      if (taskIndex != -1) {
        final task = project.tasks[taskIndex];
        if (task.goal == null) return;
        
        TaskGoal? newGoal;
        
        task.goal!.map(
          numeric: (n) {
             if (amount == null) return;
             final newCurrent = n.current + amount;
             final transaction = GoalTransaction(
               id: uuid.v4(),
               amount: amount,
               date: DateTime.now(),
               note: note
             );
             newGoal = n.copyWith(
               current: newCurrent,
               history: [...n.history, transaction]
             );
          }, 
          habit: (h) {
            if (isSuccess == null) return;
            final entry = HabitRecord(
               date: DateTime.now(),
               isSuccess: isSuccess,
               note: note
            );
            newGoal = h.copyWith(
               history: [...h.history, entry]
            );
          }
        );
        
        if (newGoal != null) {
           final newTask = task.copyWith(goal: newGoal);
           final newTasksList = List<Task>.from(project.tasks);
           newTasksList[taskIndex] = newTask;
           
           final newProject = project.copyWith(tasks: newTasksList);
           _projects[i] = newProject;
           
           notifyListeners();
           _repository.saveTask(newTask);
           _markdownPersistence.saveProject(newProject);
        }
        return;
      }
    }
  }

  // --- MCP / External Sync Methods ---

  void upsertProject(Project project) {
    // Note: If using upsert from MCP, ensure tags are handled. 
    // Usually project comes fully formed.
    // If not, we might want to re-parse title here too, but let's trust the input or model.
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    notifyListeners();
    _repository.saveProject(project);
  }

  void upsertTask(Task task) {
    if (task.projectId == null) return;
    
    final pIndex = _projects.indexWhere((p) => p.id == task.projectId);
    if (pIndex == -1) {
      debugPrint("Cannot upsert task ${task.id}: Project ${task.projectId} not found.");
      return;
    }
    
    final project = _projects[pIndex];
    final tIndex = project.tasks.indexWhere((t) => t.id == task.id);
    
    List<Task> newTasks;
    if (tIndex != -1) {
      newTasks = List<Task>.from(project.tasks);
      newTasks[tIndex] = task;
    } else {
      newTasks = List<Task>.from(project.tasks)..add(task);
    }
    
    final newProject = project.copyWith(tasks: newTasks);
    _projects[pIndex] = newProject;
    
    notifyListeners();
    _repository.saveTask(task);
  }

  void deleteItem(String itemId) {
    // Check if it is a Project
    int projectIndex = _projects.indexWhere((p) => p.id == itemId);
    if (projectIndex != -1) {
       final project = _projects[projectIndex];
       _projects.removeAt(projectIndex);
       _repository.deleteProject(itemId);
       _markdownPersistence.deleteProject(project);
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
        _markdownPersistence.saveProject(newProject);
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
           _markdownPersistence.saveProject(newProject);
           notifyListeners();
           return;
        }
      }
    }
  }

  void _cancelDebounce(String taskId) {
    if (_debounceTimers.containsKey(taskId)) {
      _debounceTimers[taskId]!.cancel();
      _debounceTimers.remove(taskId);
    }
  }

  Future<void> setItemStatus(String itemId, bool isCompleted) async {
    // Cancel any pending debounce saves to prevent overwriting
    _cancelDebounce(itemId);

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
          
          await _repository.saveTask(newTask);
          await _markdownPersistence.saveProject(newProject);
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
            
            await _repository.saveTask(newTask);
            await _markdownPersistence.saveProject(newProject);
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  Future<void> setAiStatus(String itemId, AiStatus status) async {
    // Cancel any pending debounce saves to prevent overwriting
    _cancelDebounce(itemId);
    
    // If status is done, also mark as completed
    final shouldComplete = status == AiStatus.done;
    
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      for (var j = 0; j < project.tasks.length; j++) {
        final task = project.tasks[j];
        
        if (task.id == itemId) {
          final newTask = task.copyWith(
            aiStatus: status,
            isCompleted: shouldComplete ? true : task.isCompleted,
          );
          final newTasksList = List<Task>.from(project.tasks);
          newTasksList[j] = newTask;
          
          final newProject = project.copyWith(tasks: newTasksList);
          _projects[i] = newProject;
          
          await _repository.saveTask(newTask);
          await _markdownPersistence.saveProject(newProject);
          notifyListeners();
          return;
        }
        
        for (var k = 0; k < task.subtasks.length; k++) {
          final subtask = task.subtasks[k];
          if (subtask.id == itemId) {
            final newSubtask = subtask.copyWith(
              aiStatus: status,
              isCompleted: shouldComplete ? true : subtask.isCompleted,
            );
            final newSubtasks = List<Subtask>.from(task.subtasks);
            newSubtasks[k] = newSubtask;
            
            final newTask = task.copyWith(subtasks: newSubtasks);
            final newTasksList = List<Task>.from(project.tasks);
            newTasksList[j] = newTask;
            
            final newProject = project.copyWith(tasks: newTasksList);
            _projects[i] = newProject;
            
            await _repository.saveTask(newTask);
            await _markdownPersistence.saveProject(newProject);
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  void updateTitle(String itemId, String newTitle) {
    final tags = _extractTags(newTitle);

    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      
      if (project.id == itemId) {
        final newProject = project.copyWith(title: newTitle, tags: tags);
        _projects[i] = newProject;
        notifyListeners();
        _debounceSave(newProject);
        return;
      }
      
      for (var j = 0; j < project.tasks.length; j++) {
        final task = project.tasks[j];
        
        if (task.id == itemId) {
          final newTask = task.copyWith(title: newTitle, tags: tags);
          final newTasksList = List<Task>.from(project.tasks);
          newTasksList[j] = newTask;
          
          final newProject = project.copyWith(tasks: newTasksList);
          _projects[i] = newProject;
          
          notifyListeners();
          _debounceSave(newProject, task: newTask);
          return;
        }
        
        for (var k = 0; k < task.subtasks.length; k++) {
          final subtask = task.subtasks[k];
          
          if (subtask.id == itemId) {
            final newSubtask = subtask.copyWith(title: newTitle, tags: tags);
            final newSubtasks = List<Subtask>.from(task.subtasks);
            newSubtasks[k] = newSubtask;
            
            final newTask = task.copyWith(subtasks: newSubtasks);
            final newTasksList = List<Task>.from(project.tasks);
            newTasksList[j] = newTask;
            
            final newProject = project.copyWith(tasks: newTasksList);
            _projects[i] = newProject;
            
            notifyListeners();
            _debounceSave(newProject, task: newTask);
            return;
          }
        }
      }
    }
  }

  void updateNotes(String itemId, String newNotes) {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      
      if (project.id == itemId) {
        final newProject = project.copyWith(notes: newNotes);
        _projects[i] = newProject;
        notifyListeners();
        _debounceSave(newProject);
        return;
      }
      
      for (var j = 0; j < project.tasks.length; j++) {
        final task = project.tasks[j];
        
        if (task.id == itemId) {
          final newTask = task.copyWith(notes: newNotes);
          final newTasksList = List<Task>.from(project.tasks);
          newTasksList[j] = newTask;
          
          final newProject = project.copyWith(tasks: newTasksList);
          _projects[i] = newProject;
          
          notifyListeners();
          _debounceSave(newProject, task: newTask);
          return;
        }
        
        for (var k = 0; k < task.subtasks.length; k++) {
          final subtask = task.subtasks[k];
          
          if (subtask.id == itemId) {
            final newSubtask = subtask.copyWith(notes: newNotes);
            final newSubtasks = List<Subtask>.from(task.subtasks);
            newSubtasks[k] = newSubtask;
            
            final newTask = task.copyWith(subtasks: newSubtasks);
            final newTasksList = List<Task>.from(project.tasks);
            newTasksList[j] = newTask;
            
            final newProject = project.copyWith(tasks: newTasksList);
            _projects[i] = newProject;
            
            notifyListeners();
            _debounceSave(newProject, task: newTask);
            return;
          }
        }
      }
    }
  }
  
  void _debounceSave(Project project, {Task? task}) {
    final id = task?.id ?? project.id;
    if (_debounceTimers.containsKey(id)) {
      _debounceTimers[id]!.cancel();
    }
    _debounceTimers[id] = Timer(const Duration(milliseconds: 1000), () {
      if (task != null) {
        _repository.saveTask(task);
      } else {
        _repository.saveProject(project);
      }
      _markdownPersistence.saveProject(project);
      _debounceTimers.remove(id);
    });
  }
  
  Future<void> initData() async {
    await _repository.init();
    
    // Listen for file changes (hot reload)
    _repository.onDataChanged.listen((_) {
      print("Data change detected. Reloading...");
      _reloadProjects();
      _reloadConversations();
    });
    
    await _reloadProjects();
    await _reloadConversations();
  }
  
  Future<void> _reloadProjects() async {
    final projects = await _repository.getAllProjects();
    _projects = List.from(projects)..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  Future<void> _reloadConversations() async {
    final list = await _repository.getAllConversations();
    _conversations = List.from(list);
    notifyListeners();
  }

  // --- Conversations ---

  String createConversation(String title) {
    final conversation = Conversation(title: title);
    _conversations.insert(0, conversation); // Prepend
    notifyListeners();
    _repository.saveConversation(conversation);
    return conversation.id;
  }

  void updateConversationTitle(String id, String title) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _conversations[index].copyWith(title: title, lastModified: DateTime.now());
      _conversations[index] = updated;
      notifyListeners();
      _repository.saveConversation(updated);
    }
  }

  void updateConversationNotes(String id, String notes) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _conversations[index].copyWith(notes: notes, lastModified: DateTime.now());
      _conversations[index] = updated;
      notifyListeners();
      _repository.saveConversation(updated);
    }
  }

  void deleteConversation(String id) {
    _conversations.removeWhere((c) => c.id == id);
    notifyListeners();
    _repository.deleteConversation(id);
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
        _markdownPersistence.saveProject(_projects[i]);
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
    _markdownPersistence.saveProject(newProject);
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
        
        _repository.saveTask(newTask);
        _markdownPersistence.saveProject(newProject);
        notifyListeners();
        return;
      }
    }
  }

  // --- Chat Persistence ---

  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    await _repository.saveChatMessage(message, mode);
  }

  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    return _repository.getChatHistory(mode, conversationId: conversationId);
  }

  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    await _repository.clearChatHistory(mode, conversationId: conversationId);
  }

  // --- Knowledge Base ---

  Future<void> saveKnowledge(String content) async {
    print("[VERIFY_FLOW] Saving knowledge: $content");
    final knowledge = Knowledge(content: content);
    await _repository.saveKnowledge(knowledge);
    notifyListeners();
  }

  Future<void> updateKnowledge(Knowledge knowledge) async {
    await _repository.saveKnowledge(knowledge);
    notifyListeners();
  }

  Future<void> deleteKnowledge(String id) async {
    await _repository.deleteKnowledge(id);
    notifyListeners();
  }

  Future<List<Knowledge>> getAllKnowledge() async {
    return _repository.getAllKnowledge();
  }

  void clear() {
    _projects.clear();
    _conversations.clear();
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
