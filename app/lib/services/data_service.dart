import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/ai_models.dart';
import '../data/repository/storage_repository.dart';

const uuid = Uuid();

class TaggedItem {
  final String id;
  final String title;
  final String type; // 'project', 'task', 'subtask'
  final dynamic originalObject;
  
  TaggedItem(this.id, this.title, this.type, this.originalObject);
}

class ItemPath {
  final int projectIndex;
  final int? taskIndex;
  final int? subtaskIndex;
  
  ItemPath({required this.projectIndex, this.taskIndex, this.subtaskIndex});
  
  bool get isProject => taskIndex == null;
  bool get isTask => taskIndex != null && subtaskIndex == null;
  bool get isSubtask => subtaskIndex != null;
}

class DataService extends ChangeNotifier {
  final StorageRepository _repository;
  List<Project> _projects = [];
  final Map<String, Timer> _debounceTimers = {};
  
  // Conversations Cache
  List<Conversation> _conversations = [];
  List<Memory> _memories = [];

  // Session Indexing for Agents
  final List<String> _sessionIndexMap = [];

  DataService(this._repository);

  List<Project> get projects => _projects;
  List<Conversation> get conversations => _conversations;
  List<Memory> get memories => _memories;

  // --- Internal Helpers ---

  ItemPath? _findItemPath(String id) {
    for (var i = 0; i < _projects.length; i++) {
      if (_projects[i].id == id) return ItemPath(projectIndex: i);
      
      final project = _projects[i];
      for (var j = 0; j < project.tasks.length; j++) {
        if (project.tasks[j].id == id) {
          return ItemPath(projectIndex: i, taskIndex: j);
        }
        
        final task = project.tasks[j];
        for (var k = 0; k < task.subtasks.length; k++) {
          if (task.subtasks[k].id == id) {
            return ItemPath(projectIndex: i, taskIndex: j, subtaskIndex: k);
          }
        }
      }
    }
    return null;
  }

  // --- Session Indexing ---

  void clearSessionIndex() => _sessionIndexMap.clear();

  int addToSessionIndex(String id) {
    final index = _sessionIndexMap.indexOf(id);
    if (index != -1) return index + 1;
    _sessionIndexMap.add(id);
    return _sessionIndexMap.length;
  }

  String? getIdFromSessionIndex(int index) {
    if (index < 1 || index > _sessionIndexMap.length) return null;
    return _sessionIndexMap[index - 1];
  }

  // --- Local Image Artifacts ---
  
  Future<String> saveImageArtifact(Uint8List bytes, String filename) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    final baseDir = home != null ? '$home/.assisted_intelligence' : 'data';
    final imagesDir = Directory('$baseDir/artifacts/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final file = File('${imagesDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.absolute.path;
  }

  Future<void> addLocalImagePath(String itemId, String path) async {
    final pathInfo = _findItemPath(itemId);
    if (pathInfo == null) return;

    final project = _projects[pathInfo.projectIndex];
    
    if (pathInfo.isTask) {
      final task = project.tasks[pathInfo.taskIndex!];
      if (task.localImagePaths.contains(path)) return;
      final newTask = task.copyWith(localImagePaths: [...task.localImagePaths, path]);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _repository.saveTask(newTask);
    } else if (pathInfo.isSubtask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final subtask = task.subtasks[pathInfo.subtaskIndex!];
      if (subtask.localImagePaths.contains(path)) return;
      
      final newSubtask = subtask.copyWith(localImagePaths: [...subtask.localImagePaths, path]);
      final newSubtasks = List<Subtask>.from(task.subtasks)..[pathInfo.subtaskIndex!] = newSubtask;
      final newTask = task.copyWith(subtasks: newSubtasks);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _repository.saveTask(newTask);
    }
  }

  Future<void> removeLocalImagePath(String itemId, String path) async {
    final pathInfo = _findItemPath(itemId);
    if (pathInfo == null) return;

    final project = _projects[pathInfo.projectIndex];

    if (pathInfo.isTask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final newPaths = List<String>.from(task.localImagePaths)..remove(path);
      if (newPaths.length == task.localImagePaths.length) return;
      
      final newTask = task.copyWith(localImagePaths: newPaths);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _repository.saveTask(newTask);
    } else if (pathInfo.isSubtask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final subtask = task.subtasks[pathInfo.subtaskIndex!];
      final newPaths = List<String>.from(subtask.localImagePaths)..remove(path);
      if (newPaths.length == subtask.localImagePaths.length) return;
      
      final newSubtask = subtask.copyWith(localImagePaths: newPaths);
      final newSubtasks = List<Subtask>.from(task.subtasks)..[pathInfo.subtaskIndex!] = newSubtask;
      final newTask = task.copyWith(subtasks: newSubtasks);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _repository.saveTask(newTask);
    }
  }

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

  // --- AI / UI Tool Interface ---

  Future<String> addProject(String title) async {
    return insertProject(title, _projects.length);
  }

  Future<String> insertProject(String title, int index) async {
    print("[VERIFY_FLOW] Data Update: insertProject($title) at $index");
    
    final tags = title.extractTags();
    final project = Project(id: uuid.v4(), title: title, order: index.toDouble(), tags: tags);
    
    final newList = List<Project>.from(_projects);
    if (index >= newList.length) {
      newList.add(project);
    } else {
      newList.insert(index, project);
    }
    _projects = newList;

    // Optimistic UI: Notify immediately
    notifyListeners();

    // Persist in background
    _persistProjectList();
    
    return project.id;
  }

  Future<void> _persistProjectList() async {
    final updatedProjects = List<Project>.from(_projects);
    for (int i = 0; i < updatedProjects.length; i++) {
      final p = updatedProjects[i].copyWith(order: i.toDouble());
      await _repository.saveProject(p);
    }
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
      final tags = title.extractTags();
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
      }

      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pIndex] = newProject;
      
      // Optimistic UI
      notifyListeners();
      
      _cancelDebounce(project.id);
      
      // Persist in background
      _repository.saveProject(newProject);
      for (final t in newTasks) {
        _repository.saveTask(t);
      }

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
        final tags = title.extractTags();
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
        _projects = List<Project>.from(_projects)..[i] = newProject;
        
        // Optimistic UI
        notifyListeners();
        
        // Persist in background
        _repository.saveTask(newTask);
        
        return subtask.id;
      }
    }
    return null;
  }

  void setTaskGoal(String taskId, TaskGoal goal) {
    final pathInfo = _findItemPath(taskId);
    if (pathInfo == null || !pathInfo.isTask) return;

    final project = _projects[pathInfo.projectIndex];
    final task = project.tasks[pathInfo.taskIndex!];
    final newTask = task.copyWith(goal: goal);
    
    final newTasksList = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
    final newProject = project.copyWith(tasks: newTasksList);
    _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
    
    notifyListeners();
    _repository.saveTask(newTask);
  }

  void recordGoalProgress(String taskId, {double? amount, bool? isSuccess, String? note}) {
    final pathInfo = _findItemPath(taskId);
    if (pathInfo == null || !pathInfo.isTask) return;

    final project = _projects[pathInfo.projectIndex];
    final task = project.tasks[pathInfo.taskIndex!];
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
        final newTasksList = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
        
        final newProject = project.copyWith(tasks: newTasksList);
        _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
        
        notifyListeners();
        _repository.saveTask(newTask);
    }
  }

  // --- MCP / External Sync Methods ---

  void upsertProject(Project project) {
    final index = _projects.indexWhere((p) => p.id == project.id);
    final newList = List<Project>.from(_projects);
    if (index != -1) {
      newList[index] = project;
    } else {
      newList.add(project);
    }
    _projects = newList;
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
    _projects = List<Project>.from(_projects)..[pIndex] = newProject;
    
    notifyListeners();
    _repository.saveTask(task);
  }

  void deleteItem(String itemId) {
    // Check if it is a Project
    int projectIndex = _projects.indexWhere((p) => p.id == itemId);
    if (projectIndex != -1) {
       _cancelDebounce(itemId); // Prevent race condition
       _projects = List<Project>.from(_projects)..removeAt(projectIndex);
       _repository.deleteProject(itemId);
       notifyListeners();
       return;
    }
    
    final pathInfo = _findItemPath(itemId);
    if (pathInfo == null) return;

    final project = _projects[pathInfo.projectIndex];

    if (pathInfo.isTask) {
      _cancelDebounce(itemId); // Prevent race condition
      
      final newTasks = List<Task>.from(project.tasks)..removeAt(pathInfo.taskIndex!);
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      
      _repository.deleteTask(itemId);
      notifyListeners();
    } else if (pathInfo.isSubtask) {
      final task = project.tasks[pathInfo.taskIndex!];
      _cancelDebounce(task.id); // Prevent race condition (subtasks are debounced on task)
      
      final newSubtasks = List<Subtask>.from(task.subtasks)..removeAt(pathInfo.subtaskIndex!);
      final newTask = task.copyWith(subtasks: newSubtasks);
      
      final newTasksList = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasksList);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      
      _repository.saveTask(newTask);
      notifyListeners();
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

    final pathInfo = _findItemPath(itemId);
    if (pathInfo == null) return;

    final project = _projects[pathInfo.projectIndex];

    if (pathInfo.isTask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final newTask = task.copyWith(isCompleted: isCompleted);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _repository.saveTask(newTask);
    } else if (pathInfo.isSubtask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final subtask = task.subtasks[pathInfo.subtaskIndex!];
      final newSubtask = subtask.copyWith(isCompleted: isCompleted);
      final newSubtasks = List<Subtask>.from(task.subtasks)..[pathInfo.subtaskIndex!] = newSubtask;
      final newTask = task.copyWith(subtasks: newSubtasks);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _repository.saveTask(newTask);
    }
  }

  Future<void> setAiStatus(String itemId, AiStatus status) async {
    // Cancel any pending debounce saves to prevent overwriting
    _cancelDebounce(itemId);
    
    // If status is done, also mark as completed
    final shouldComplete = status == AiStatus.done;

    final pathInfo = _findItemPath(itemId);
    if (pathInfo == null) return;

    final project = _projects[pathInfo.projectIndex];

    if (pathInfo.isTask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final newTask = task.copyWith(
        aiStatus: status,
        isCompleted: shouldComplete ? true : task.isCompleted,
      );
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _repository.saveTask(newTask);
    } else if (pathInfo.isSubtask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final subtask = task.subtasks[pathInfo.subtaskIndex!];
      final newSubtask = subtask.copyWith(
        aiStatus: status,
        isCompleted: shouldComplete ? true : subtask.isCompleted,
      );
      final newSubtasks = List<Subtask>.from(task.subtasks)..[pathInfo.subtaskIndex!] = newSubtask;
      final newTask = task.copyWith(subtasks: newSubtasks);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _repository.saveTask(newTask);
    }
  }

  void updateTitle(String itemId, String newTitle) {
    final tags = newTitle.extractTags();
    final pathInfo = _findItemPath(itemId);
    if (pathInfo == null) return;

    final project = _projects[pathInfo.projectIndex];

    if (pathInfo.isProject) {
      final newProject = project.copyWith(title: newTitle, tags: tags);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _debounceSave(newProject);
    } else if (pathInfo.isTask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final newTask = task.copyWith(title: newTitle, tags: tags);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _debounceSave(newProject, task: newTask);
    } else if (pathInfo.isSubtask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final subtask = task.subtasks[pathInfo.subtaskIndex!];
      final newSubtask = subtask.copyWith(title: newTitle, tags: tags);
      final newSubtasks = List<Subtask>.from(task.subtasks)..[pathInfo.subtaskIndex!] = newSubtask;
      final newTask = task.copyWith(subtasks: newSubtasks);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _debounceSave(newProject, task: newTask);
    }
  }

  void updateNotes(String itemId, String newNotes) {
    final pathInfo = _findItemPath(itemId);
    if (pathInfo == null) return;

    final project = _projects[pathInfo.projectIndex];

    if (pathInfo.isProject) {
      final newProject = project.copyWith(notes: newNotes);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _debounceSave(newProject);
    } else if (pathInfo.isTask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final newTask = task.copyWith(notes: newNotes);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _debounceSave(newProject, task: newTask);
    } else if (pathInfo.isSubtask) {
      final task = project.tasks[pathInfo.taskIndex!];
      final subtask = task.subtasks[pathInfo.subtaskIndex!];
      final newSubtask = subtask.copyWith(notes: newNotes);
      final newSubtasks = List<Subtask>.from(task.subtasks)..[pathInfo.subtaskIndex!] = newSubtask;
      final newTask = task.copyWith(subtasks: newSubtasks);
      final newTasks = List<Task>.from(project.tasks)..[pathInfo.taskIndex!] = newTask;
      final newProject = project.copyWith(tasks: newTasks);
      _projects = List<Project>.from(_projects)..[pathInfo.projectIndex] = newProject;
      notifyListeners();
      _debounceSave(newProject, task: newTask);
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
      _debounceTimers.remove(id);
    });
  }
  
  bool _isInitialized = false;
  StreamSubscription? _dataSubscription;

  Future<void> initData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _repository.init();
    
    // Listen for file changes (hot reload)
    _dataSubscription = _repository.onDataChanged.listen((_) {
      print("Data change detected. Reloading...");
      _reloadProjects();
      _reloadConversations();
      _reloadMemories();
    });
    
    await _reloadProjects();
    await _reloadConversations();
    await _reloadMemories();
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

  Future<void> _reloadMemories() async {
    final list = await _repository.getAllMemories();
    _memories = List.from(list);
    notifyListeners();
  }

  // --- Long-term Memory ---

  Future<void> saveMemory(String fact) async {
    final memory = Memory(fact: fact);
    _memories = List<Memory>.from(_memories)..insert(0, memory);
    notifyListeners();
    await _repository.saveMemory(memory);
  }

  Future<void> deleteMemory(String id) async {
    _memories = List<Memory>.from(_memories)..removeWhere((m) => m.id == id);
    notifyListeners();
    await _repository.deleteMemory(id);
  }

  // --- Conversations ---

  String createConversation(String title) {
    final conversation = Conversation(title: title);
    _conversations = List<Conversation>.from(_conversations)..insert(0, conversation); // Prepend
    notifyListeners();
    _repository.saveConversation(conversation);
    return conversation.id;
  }

  void updateConversationTitle(String id, String title) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _conversations[index].copyWith(title: title, lastModified: DateTime.now());
      _conversations = List<Conversation>.from(_conversations)..[index] = updated;
      notifyListeners();
      _repository.saveConversation(updated);
    }
  }

  void updateConversationNotes(String id, String notes) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _conversations[index].copyWith(notes: notes, lastModified: DateTime.now());
      _conversations = List<Conversation>.from(_conversations)..[index] = updated;
      notifyListeners();
      _repository.saveConversation(updated);
    }
  }

  void deleteConversation(String id) {
    _conversations = List<Conversation>.from(_conversations)..removeWhere((c) => c.id == id);
    notifyListeners();
    _repository.deleteConversation(id);
  }

  // --- Reordering ---

  void reorderProjects(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final newList = List<Project>.from(_projects);
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    
    // Recalculate order
    for (int i = 0; i < newList.length; i++) {
        newList[i] = newList[i].copyWith(order: i.toDouble());
        _repository.saveProject(newList[i]);
    }
    _projects = newList;
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
    _projects = List<Project>.from(_projects)..[pIndex] = newProject;
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
        _projects = List<Project>.from(_projects)..[i] = newProject;
        
        _repository.saveTask(newTask);
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
    _projects = [];
    _conversations = [];
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