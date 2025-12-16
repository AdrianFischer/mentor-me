import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../../models/ai_models.dart';
import '../schema/isar_models.dart';
import 'storage_repository.dart';

class IsarStorageRepository implements StorageRepository {
  late Isar _isar;
  final StreamController<void> _dataChangeController = StreamController<void>.broadcast();

  @override
  Stream<void> get onDataChanged => _dataChangeController.stream;

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      _isar = await Isar.open(
        [IsarProjectSchema, IsarTaskSchema, IsarChatMessageSchema, IsarKnowledgeSchema],
        directory: dir.path,
      );
    } else {
      _isar = Isar.getInstance()!;
    }
  }

  @override
  Future<List<Project>> getAllProjects() async {
    final isarProjects = await _isar.isarProjects.where().findAll();
    final projects = <Project>[];

    for (final ip in isarProjects) {
      // Ensure tasks are loaded
      await ip.tasks.load();
      
      final domainTasks = ip.tasks.map((it) => _taskToDomain(it)).toList();
      
      // Sort tasks? Or keep insertion order? Isar doesn't guarantee order unless sorted.
      // Current app relies on list order? 
      // The current JSON approach preserves array order.
      // IsarLinks doesn't strictly preserve order.
      // For now, we accept arbitrary order or sort by ID/title if needed.
      
      projects.add(Project(
        id: ip.originalId,
        title: ip.title,
        tasks: domainTasks,
      ));
    }

    return projects;
  }
  
  // Note: The current DataService logic handles "unassigned" tasks by checking for tasks 
  // that didn't fit into projects. 
  // With Isar, we can query them directly if we wanted, but getAllProjects() follows the interface.
  // If we need unassigned tasks, we might need to expose them. 
  // However, the current DataService.initData() reloads tasks and manually bins them.
  // To support that exactly, we might want to just return ALL tasks and projects and let DataService assembly?
  // But StorageRepository.getAllProjects() implies a tree.
  // Let's stick to the tree. 
  // But what about orphans?
  // We can add a method `getOrphanTasks` or just include them in a special project here.
  // The DataService does: `_reloadTasks` -> loads tasks, loads projects, matches them.
  // If we return the tree, DataService doesn't need to match.
  // Use `getAllProjects` to return the valid tree. 
  // If there are orphans in DB (e.g. from bad sync), they might be lost if we don't query them.
  // For now, let's assume `saveTask` correctly links them.

  Task _taskToDomain(IsarTask it) {
    return Task(
      id: it.originalId,
      title: it.title,
      isCompleted: it.isCompleted,
      projectId: it.projectId,
      subtasks: it.subtasks.map((s) => Subtask(
        id: s.originalId,
        title: s.title,
        isCompleted: s.isCompleted,
      )).toList(),
    );
  }

  @override
  Future<void> saveProject(Project project) async {
    await _isar.writeTxn(() async {
      // Check if exists to preserve ID
      final existing = await _isar.isarProjects.filter().originalIdEqualTo(project.id).findFirst();
      final p = existing ?? IsarProject();
      p.originalId = project.id;
      p.title = project.title;
      await _isar.isarProjects.put(p);
    });
    _dataChangeController.add(null);
  }

  @override
  Future<void> saveTask(Task task) async {
    await _isar.writeTxn(() async {
      // 1. Save the task
      final existing = await _isar.isarTasks.filter().originalIdEqualTo(task.id).findFirst();
      final t = existing ?? IsarTask();
      t.originalId = task.id;
      t.title = task.title;
      t.isCompleted = task.isCompleted;
      t.projectId = task.projectId;
      t.subtasks = task.subtasks.map((s) => IsarSubtask()
        ..originalId = s.id
        ..title = s.title
        ..isCompleted = s.isCompleted
      ).toList();

      await _isar.isarTasks.put(t);

      // 2. Link to Project if projectId is present
      if (task.projectId != null) {
        final project = await _isar.isarProjects.filter().originalIdEqualTo(task.projectId!).findFirst();
        if (project != null) {
          project.tasks.add(t);
          await project.tasks.save();
        }
      }
    });
    _dataChangeController.add(null);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _isar.writeTxn(() async {
      await _isar.isarProjects.filter().originalIdEqualTo(projectId).deleteAll();
      // Tasks are not automatically deleted unless we cascade.
      // But domain logic `DataService.deleteItem` handles tasks removal from list.
      // We should probably delete associated tasks too?
      // For now, let's just delete the project. 
      // If we want cascade delete, we need to query tasks.
      // A safe approach:
      final tasks = await _isar.isarTasks.filter().projectIdEqualTo(projectId).findAll();
      await _isar.isarTasks.deleteAll(tasks.map((e) => e.id).toList());
    });
    _dataChangeController.add(null);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _isar.writeTxn(() async {
      await _isar.isarTasks.filter().originalIdEqualTo(taskId).deleteAll();
    });
    _dataChangeController.add(null);
  }

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    final im = IsarChatMessage()
      ..originalId = message.id
      ..text = message.text
      ..isUser = message.isUser
      ..timestamp = message.timestamp
      ..mode = mode;

    await _isar.writeTxn(() async {
      await _isar.isarChatMessages.put(im);
    });
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode) async {
    final msgs = await _isar.isarChatMessages
        .filter()
        .modeEqualTo(mode)
        .sortByTimestamp()
        .findAll();

    return msgs.map((m) => ChatMessage(
      text: m.text,
      isUser: m.isUser,
      id: m.originalId,
      timestamp: m.timestamp,
    )).toList();
  }

  @override
  Future<void> clearChatHistory(String mode) async {
    await _isar.writeTxn(() async {
      await _isar.isarChatMessages.filter().modeEqualTo(mode).deleteAll();
    });
  }

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
    final ik = IsarKnowledge()
      ..originalId = knowledge.id
      ..content = knowledge.content
      ..createdAt = knowledge.createdAt
      ..updatedAt = knowledge.updatedAt;

    await _isar.writeTxn(() async {
      // Check for duplicates or update?
      // Assuming ID is unique and persistent.
      final existing = await _isar.isarKnowledges.filter().originalIdEqualTo(knowledge.id).findFirst();
      if (existing != null) {
        ik.id = existing.id; // Preserve internal ID
      }
      await _isar.isarKnowledges.put(ik);
    });
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    final items = await _isar.isarKnowledges.where().findAll();
    return items.map((i) => Knowledge(
      id: i.originalId,
      content: i.content,
      createdAt: i.createdAt,
      updatedAt: i.updatedAt,
    )).toList();
  }
}
