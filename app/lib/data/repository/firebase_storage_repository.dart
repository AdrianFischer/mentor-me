import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../../models/ai_models.dart';
import 'storage_repository.dart';

class FirebaseStorageRepository implements StorageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final _controller = StreamController<void>.broadcast();
  List<StreamSubscription> _subscriptions = [];

  String? _currentUserId;

  String get _userId {
    if (_currentUserId != null) return _currentUserId!;
    debugPrint("WARN: Using hardcoded DEV user ID because Auth failed.");
    return "dev_sync_user_id";
  }

  DocumentReference get _userDoc => _firestore.collection('users').doc(_userId);

  @override
  Stream<void> get onDataChanged => _controller.stream;

  @override
  Future<void> init() async {
    // 1. Set initial state
    final user = _auth.currentUser;
    debugPrint("FirebaseStorageRepository: init() called. currentUser: ${user?.uid}");
    
    if (user != null) {
      _currentUserId = user.uid;
    } else {
      // Fallback for dev
      _currentUserId = "dev_sync_user_id"; 
    }
    _setupListeners();

    // 2. Listen to future Auth State Changes
    _auth.authStateChanges().listen((streamUser) {
      debugPrint("FirebaseStorageRepository: authStateChange event. User: ${streamUser?.uid}");
      
      if (streamUser != null) {
        if (_currentUserId != streamUser.uid) {
           _currentUserId = streamUser.uid;
           debugPrint("FirebaseStorageRepository: User changed to $_currentUserId");
           _setupListeners();
           _controller.add(null);
        }
      } else {
         // Don't clear if we are in dev mode and it was already null/dev
         if (_auth.currentUser == null) {
            debugPrint("FirebaseStorageRepository: User logged out. Reverting to dev user.");
            _currentUserId = "dev_sync_user_id";
            _setupListeners();
            _controller.add(null);
         }
      }
    });
  }

  void _cancelListeners() {
    for (var sub in _subscriptions) sub.cancel();
    _subscriptions.clear();
  }

  void _setupListeners() {
    _cancelListeners();
    if (_currentUserId == null) return;

    // Listen to collections to trigger onDataChanged
    void notify() => _controller.add(null);

    _subscriptions.add(_userDoc.collection('projects').snapshots().listen((_) => notify()));
    _subscriptions.add(_userDoc.collection('tasks').snapshots().listen((_) => notify()));
    _subscriptions.add(_userDoc.collection('conversations').snapshots().listen((_) => notify()));
    _subscriptions.add(_userDoc.collection('chat_messages').snapshots().listen((_) => notify()));
    _subscriptions.add(_userDoc.collection('knowledge').snapshots().listen((_) => notify()));
  }

  // Helper to get Timestamp from DateTime
  Timestamp _toTimestamp(DateTime dt) => Timestamp.fromDate(dt);
  DateTime _fromTimestamp(Timestamp ts) => ts.toDate();

  // --- Projects & Tasks ---

  @override
  Future<List<Project>> getAllProjects() async {
    if (_currentUserId == null) {
      debugPrint("WARN: getAllProjects called but user is null");
      return [];
    }
    try {
      // 1. Fetch all projects
      final projectsSnapshot = await _userDoc.collection('projects').get();
      final projectsData = projectsSnapshot.docs.map((doc) => doc.data()).toList();

      // 2. Fetch all tasks
      final tasksSnapshot = await _userDoc.collection('tasks').get();
      final tasksData = tasksSnapshot.docs.map((doc) => doc.data()).toList();

      // 3. Map tasks by projectId
      final tasksByProject = <String, List<Task>>{};
      
      for (var data in tasksData) {
        // Convert Timestamps in subtasks/goals if needed.
        // Task.fromJson expects standard JSON types. 
        // Firestore returns Timestamp for DateTimes. Freezed might struggle if we don't convert.
        final json = _convertTimestamps(data);
        final task = Task.fromJson(json);
        
        final pid = task.projectId;
        if (pid != null) {
           tasksByProject.putIfAbsent(pid, () => []).add(task);
        }
      }

      // 4. Assemble Projects
      final projects = <Project>[];
      for (var data in projectsData) {
        final json = _convertTimestamps(data);
        var project = Project.fromJson(json);
        
        // Attach tasks
        final projectTasks = tasksByProject[project.id] ?? [];
        // Sort tasks by order if needed, though usually UI handles it or we do it here.
        // The Isar repo likely returned them sorted.
        projectTasks.sort((a, b) => a.order.compareTo(b.order));
        
        project = project.copyWith(tasks: projectTasks);
        projects.add(project);
      }
      
      // Sort projects
      projects.sort((a, b) => a.order.compareTo(b.order));

      return projects;
    } catch (e, stack) {
      debugPrint("Error fetching projects: $e\n$stack");
      return [];
    }
  }

  @override
  Future<void> saveProject(Project project) async {
    if (_currentUserId == null) {
       debugPrint("ERROR: Cannot saveProject ${project.id} - User not logged in");
       return;
    }
    // We save the project metadata. Tasks are saved separately.
    // Ensure we don't save the 'tasks' list into the project document to avoid duplication/bloat.
    final json = project.toJson();
    json.remove('tasks'); // Remove the embedded tasks
    
    await _userDoc.collection('projects').doc(project.id).set(json);
    
    // Also save all tasks? Isar does "cascade" save usually.
    // For now, we assume tasks are saved via saveTask individually, 
    // BUT if this is a new project with tasks, we might need to save them.
    // Let's iterate and save them just in case, or assume the caller handles it.
    // The previous Isar implementation likely saved the graph.
    for (var task in project.tasks) {
      await saveTask(task.copyWith(projectId: project.id));
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    if (_currentUserId == null) return;
    await _userDoc.collection('projects').doc(projectId).delete();
    
    // Delete associated tasks
    final tasksSnapshot = await _userDoc.collection('tasks').where('projectId', isEqualTo: projectId).get();
    for (var doc in tasksSnapshot.docs) {
      await _userDoc.collection('tasks').doc(doc.id).delete();
    }
  }

  @override
  Future<void> saveTask(Task task) async {
    if (_currentUserId == null) {
       debugPrint("ERROR: Cannot saveTask ${task.id} - User not logged in");
       return;
    }
    final json = task.toJson();
    // Ensure nested timestamps (in subtasks, goals) are handled by Firestore automatically?
    // Firestore accepts Map, String, Number, Boolean, Null, Array, Binary, GeoPoint, Timestamp.
    // Freezed toJson produces String for DateTime (ISO8601).
    // Firestore DOES NOT automatically convert ISO8601 Strings to Timestamps.
    // It stores them as Strings. This is fine, but we need to ensure consistent parsing.
    // However, if we want native Firestore Timestamps, we'd need to convert.
    // DECISION: Store DateTimes as ISO8601 Strings (default Freezed behavior).
    // It's easier than walking the JSON tree to convert to Timestamp.
    // Wait, my _convertTimestamps helper above assumed Timestamps. 
    // If I store as Strings, I don't need _convertTimestamps.
    
    await _userDoc.collection('tasks').doc(task.id).set(json);
  }

  @override
  Future<void> deleteTask(String taskId) async {
     if (_currentUserId == null) return;
     await _userDoc.collection('tasks').doc(taskId).delete();
  }

  // --- Conversations & Chat ---

  @override
  Future<void> saveConversation(Conversation conversation) async {
    if (_currentUserId == null) return;
    final data = {
      'id': conversation.id,
      'title': conversation.title,
      'lastModified': _toTimestamp(conversation.lastModified),
      'notes': conversation.notes,
    };
    await _userDoc.collection('conversations').doc(conversation.id).set(data);
  }

  @override
  Future<List<Conversation>> getAllConversations() async {
    if (_currentUserId == null) return [];
    final snapshot = await _userDoc.collection('conversations').orderBy('lastModified', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Conversation(
        id: data['id'],
        title: data['title'],
        lastModified: _fromTimestamp(data['lastModified']),
        notes: data['notes'],
      );
    }).toList();
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    if (_currentUserId == null) return;
    await _userDoc.collection('conversations').doc(conversationId).delete();
    // Delete messages for this conversation
    final messages = await _userDoc.collection('chat_messages').where('conversationId', isEqualTo: conversationId).get();
    for (var doc in messages.docs) {
       await _userDoc.collection('chat_messages').doc(doc.id).delete();
    }
  }

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    if (_currentUserId == null) return;
    // Mode is legacy usage, we mostly use conversationId now.
    // If conversationId is null, we might assign it to a 'global' one or keep it null.
    final data = {
      'id': message.id,
      'text': message.text,
      'isUser': message.isUser,
      'timestamp': _toTimestamp(message.timestamp),
      'conversationId': message.conversationId,
      'mode': mode, // Keep mode just in case
    };
    await _userDoc.collection('chat_messages').doc(message.id).set(data);
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    if (_currentUserId == null) return [];
    Query query = _userDoc.collection('chat_messages');
    
    if (conversationId != null) {
      query = query.where('conversationId', isEqualTo: conversationId);
    } else {
      // Legacy behavior: filter by mode if no conversation
       query = query.where('mode', isEqualTo: mode).where('conversationId', isNull: true);
    }
    
    // Sort by timestamp
    query = query.orderBy('timestamp', descending: false);
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ChatMessage(
        id: data['id'],
        text: data['text'],
        isUser: data['isUser'],
        timestamp: _fromTimestamp(data['timestamp']),
        conversationId: data['conversationId'],
      );
    }).toList();
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
     if (_currentUserId == null) return;
     // This seems duplicated with deleteConversation logic, but specific to messages
     final msgs = await getChatHistory(mode, conversationId: conversationId);
     for (var msg in msgs) {
       await _userDoc.collection('chat_messages').doc(msg.id).delete();
     }
  }

  // --- Knowledge ---

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
    if (_currentUserId == null) return;
    final data = {
      'id': knowledge.id,
      'content': knowledge.content,
      'createdAt': _toTimestamp(knowledge.createdAt),
      'updatedAt': _toTimestamp(knowledge.updatedAt),
    };
    await _userDoc.collection('knowledge').doc(knowledge.id).set(data);
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    if (_currentUserId == null) return [];
    final snapshot = await _userDoc.collection('knowledge').orderBy('updatedAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Knowledge(
        id: data['id'],
        content: data['content'],
        createdAt: _fromTimestamp(data['createdAt']),
        updatedAt: _fromTimestamp(data['updatedAt']),
      );
    }).toList();
  }

  @override
  Future<void> deleteKnowledge(String id) async {
    if (_currentUserId == null) return;
    await _userDoc.collection('knowledge').doc(id).delete();
  }
  
  // Recursive helper to convert Timestamps to ISO8601 Strings if they exist in the Map
  // (Used when reading from Firestore if we decided to store as Timestamps, 
  // OR if we stored as Strings, we don't need this.
  // BUT: The plan above for 'Tasks' was to store as JSON (Strings).
  // The plan for 'AiModels' was manual mapping (Timestamps).
  // So for Tasks, we just need to ensure we don't accidentally get Timestamps.)
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    // If we just store as JSON, Firestore stores Strings.
    // If we modify specific fields to be Timestamps, we need to convert back.
    // For now, since Task.toJson() output Strings for DateTime, Firestore saves them as Strings.
    // So reading them back requires no conversion for Freezed.
    return data; 
  }
}
