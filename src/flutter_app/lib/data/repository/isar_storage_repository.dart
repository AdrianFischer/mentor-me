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
    final isarProjects = await _isar.isarProjects.where().sortByOrder().findAll();
    final projects = <Project>[];

    for (final ip in isarProjects) {
      // Ensure tasks are loaded
      await ip.tasks.load();
      
      // Sort tasks by order explicitly since IsarLinks don't guarantee order
      final sortedTasks = ip.tasks.toList()..sort((a, b) => a.order.compareTo(b.order));
      final domainTasks = sortedTasks.map((it) => _taskToDomain(it)).toList();
      
      projects.add(Project(
        id: ip.originalId,
        title: ip.title,
        tasks: domainTasks,
        order: ip.order,
      ));
    }

    return projects;
  }
  
  Task _taskToDomain(IsarTask it) {
    return Task(
      id: it.originalId,
      title: it.title,
      isCompleted: it.isCompleted,
      projectId: it.projectId,
      order: it.order,
      subtasks: it.subtasks.map((s) => Subtask(
        id: s.originalId,
        title: s.title,
        isCompleted: s.isCompleted,
        order: s.order,
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
      p.order = project.order;
      await _isar.isarProjects.put(p);
    });
    // _dataChangeController.add(null); // Prevent self-reload loop
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
      t.order = task.order;
      t.subtasks = task.subtasks.map((s) => IsarSubtask()
        ..originalId = s.id
        ..title = s.title
        ..isCompleted = s.isCompleted
        ..order = s.order
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
    // _dataChangeController.add(null);
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
    // _dataChangeController.add(null);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _isar.writeTxn(() async {
      await _isar.isarTasks.filter().originalIdEqualTo(taskId).deleteAll();
    });
    // _dataChangeController.add(null);
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
