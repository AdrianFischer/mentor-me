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
        [IsarProjectSchema, IsarTaskSchema, IsarConversationSchema, IsarChatMessageSchema, IsarKnowledgeSchema],
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
        tags: ip.tags,
        notes: ip.notes,
      ));
    }

    return projects;
  }
  
  Task _taskToDomain(IsarTask it) {
    TaskGoal? goal;
    if (it.goal != null) {
      if (it.goal!.type == 'numeric') {
        goal = TaskGoal.numeric(
          target: it.goal!.numericTarget ?? 0.0,
          current: it.goal!.numericCurrent ?? 0.0,
          unit: it.goal!.numericUnit,
          history: it.goal!.transactions.map((t) => GoalTransaction(
            id: t.id,
            amount: t.amount,
            date: t.date,
            note: t.note,
          )).toList(),
        );
      } else if (it.goal!.type == 'habit') {
        goal = TaskGoal.habit(
          targetFrequency: it.goal!.habitTargetFrequency ?? 0.0,
          history: it.goal!.habitHistory.map((h) => HabitRecord(
            date: h.date,
            isSuccess: h.isSuccess,
            note: h.note,
          )).toList(),
        );
      }
    }

    return Task(
      id: it.originalId,
      title: it.title,
      isCompleted: it.isCompleted,
      projectId: it.projectId,
      order: it.order,
      tags: it.tags,
      notes: it.notes,
      subtasks: it.subtasks.map((s) => Subtask(
        id: s.originalId,
        title: s.title,
        isCompleted: s.isCompleted,
        order: s.order,
        tags: s.tags,
        notes: s.notes,
      )).toList(),
      goal: goal,
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
      p.tags = project.tags;
      p.notes = project.notes;
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
      t.tags = task.tags;
      t.notes = task.notes;
      t.subtasks = task.subtasks.map((s) => IsarSubtask()
        ..originalId = s.id
        ..title = s.title
        ..isCompleted = s.isCompleted
        ..order = s.order
        ..tags = s.tags
        ..notes = s.notes
      ).toList();

      if (task.goal != null) {
        final isarGoal = IsarTaskGoal();
        task.goal!.map(
          numeric: (g) {
            isarGoal.type = 'numeric';
            isarGoal.numericTarget = g.target;
            isarGoal.numericCurrent = g.current;
            isarGoal.numericUnit = g.unit;
            isarGoal.transactions = g.history.map((tr) => IsarGoalTransaction()
              ..id = tr.id
              ..amount = tr.amount
              ..date = tr.date
              ..note = tr.note
            ).toList();
          },
          habit: (g) {
            isarGoal.type = 'habit';
            isarGoal.habitTargetFrequency = g.targetFrequency;
            isarGoal.habitHistory = g.history.map((h) => IsarHabitRecord()
              ..date = h.date
              ..isSuccess = h.isSuccess
              ..note = h.note
            ).toList();
          },
        );
        t.goal = isarGoal;
      } else {
        t.goal = null;
      }

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
      await _isar.isarTasks.deleteAll(tasks.map((e) => e.id).where((id) => id != null).cast<int>().toList());
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

  // --- Conversations ---

  @override
  Future<void> saveConversation(Conversation conversation) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.isarConversations.filter().originalIdEqualTo(conversation.id).findFirst();
      final c = existing ?? IsarConversation();
      c.originalId = conversation.id;
      c.title = conversation.title;
      c.lastModified = conversation.lastModified;
      c.notes = conversation.notes;
      await _isar.isarConversations.put(c);
    });
  }

  @override
  Future<List<Conversation>> getAllConversations() async {
    final list = await _isar.isarConversations.where().sortByLastModifiedDesc().findAll();
    return list.map((c) => Conversation(
      id: c.originalId,
      title: c.title,
      lastModified: c.lastModified,
      notes: c.notes,
    )).toList();
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    await _isar.writeTxn(() async {
      await _isar.isarConversations.filter().originalIdEqualTo(conversationId).deleteAll();
      // Also delete messages associated with this conversation
      await _isar.isarChatMessages.filter().conversationIdEqualTo(conversationId).deleteAll();
    });
  }

  // --- Chat Messages ---

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    final im = IsarChatMessage()
      ..originalId = message.id
      ..text = message.text
      ..isUser = message.isUser
      ..timestamp = message.timestamp
      ..mode = mode
      ..conversationId = message.conversationId;

    await _isar.writeTxn(() async {
      await _isar.isarChatMessages.put(im);
    });
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    QueryBuilder<IsarChatMessage, IsarChatMessage, QAfterFilterCondition> query = _isar.isarChatMessages.filter().modeEqualTo(mode);
    
    if (conversationId != null) {
      query = query.conversationIdEqualTo(conversationId);
    } else {
      // Legacy behavior: If conversationId is NOT provided, maybe return all? 
      // Or return those with NULL conversationId (legacy)?
      // For now, let's return those with NULL conversationId to support migration if needed, 
      // OR just return everything if we treat "mode" as the only filter for legacy.
      // But typically, we want specific context. 
      // Let's assume strict filtering if ID is null (legacy messages).
      // query = query.conversationIdIsNull(); 
    }

    final msgs = await query.sortByTimestamp().findAll();

    return msgs.map((m) => ChatMessage(
      text: m.text,
      isUser: m.isUser,
      id: m.originalId,
      timestamp: m.timestamp,
      conversationId: m.conversationId,
    )).toList();
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    await _isar.writeTxn(() async {
      var query = _isar.isarChatMessages.filter().modeEqualTo(mode);
      if (conversationId != null) {
        query = query.conversationIdEqualTo(conversationId);
      }
      await query.deleteAll();
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

  @override
  Future<void> deleteKnowledge(String id) async {
    await _isar.writeTxn(() async {
      await _isar.isarKnowledges.filter().originalIdEqualTo(id).deleteAll();
    });
  }
}