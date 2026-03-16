import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/node.dart';
import '../../models/ai_models.dart';
import 'storage_repository.dart';

class FirebaseStorageRepository implements StorageRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseStorageRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<T> _withRetry<T>(Future<T> Function() action, {int maxAttempts = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await action();
      } catch (e) {
        if (attempt >= maxAttempts) {
          debugPrint("FirebaseStorageRepository Error after $maxAttempts attempts: $e");
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  final _controller = StreamController<void>.broadcast();  final List<StreamSubscription> _subscriptions = [];

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
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  void _setupListeners() {
    _cancelListeners();
    if (_currentUserId == null) return;

    // Listen to collections to trigger onDataChanged
    void notify() => _controller.add(null);

    _subscriptions.add(_userDoc.collection('nodes').snapshots().listen((_) => notify()));
    _subscriptions.add(_userDoc.collection('conversations').snapshots().listen((_) => notify()));
    _subscriptions.add(_userDoc.collection('chat_messages').snapshots().listen((_) => notify()));
    _subscriptions.add(_userDoc.collection('knowledge').snapshots().listen((_) => notify()));
    _subscriptions.add(_userDoc.collection('memories').snapshots().listen((_) => notify()));
  }

  // Helper to get Timestamp from DateTime
  Timestamp _toTimestamp(DateTime dt) => Timestamp.fromDate(dt);
  DateTime _fromTimestamp(Timestamp ts) => ts.toDate();

  // --- Nodes ---

  @override
  Future<List<Node>> getAllNodes() async {
    if (_currentUserId == null) {
      debugPrint("WARN: getAllNodes called but user is null");
      return [];
    }
    try {
      final snapshot = await _withRetry(() => _userDoc.collection('nodes').get());
      final nodes = snapshot.docs.map((doc) {
        final json = _convertTimestamps(doc.data());
        return Node.fromJson(json);
      }).toList();

      nodes.sort((a, b) => a.order.compareTo(b.order));
      return nodes;
    } catch (e, stack) {
      debugPrint("Error fetching nodes: $e\n$stack");
      return [];
    }
  }

  @override
  Future<void> saveNode(Node node) async {
    if (_currentUserId == null) {
       debugPrint("ERROR: Cannot saveNode ${node.id} - User not logged in");
       return;
    }
    final json = node.toJson();
    await _withRetry(() => _userDoc.collection('nodes').doc(node.id).set(json));
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    if (_currentUserId == null) return;
    await _withRetry(() => _userDoc.collection('nodes').doc(nodeId).delete());
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
    await _withRetry(() => _userDoc.collection('conversations').doc(conversation.id).set(data));
  }

  @override
  Future<List<Conversation>> getAllConversations() async {
    if (_currentUserId == null) return [];
    final snapshot = await _withRetry(() => _userDoc.collection('conversations').orderBy('lastModified', descending: true).get());
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
    await _withRetry(() => _userDoc.collection('conversations').doc(conversationId).delete());
    // Delete messages for this conversation
    final messages = await _withRetry(() => _userDoc.collection('chat_messages').where('conversationId', isEqualTo: conversationId).get());
    for (var doc in messages.docs) {
       await _withRetry(() => _userDoc.collection('chat_messages').doc(doc.id).delete());
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
    await _withRetry(() => _userDoc.collection('chat_messages').doc(message.id).set(data));
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
       await _withRetry(() => _userDoc.collection('chat_messages').doc(msg.id).delete());
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
    await _withRetry(() => _userDoc.collection('knowledge').doc(knowledge.id).set(data));
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    if (_currentUserId == null) return [];
    final snapshot = await _withRetry(() => _userDoc.collection('knowledge').orderBy('updatedAt', descending: true).get());
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
    await _withRetry(() => _userDoc.collection('knowledge').doc(id).delete());
  }

  // --- Memory ---

  @override
  Future<void> saveMemory(Memory memory) async {
    if (_currentUserId == null) return;
    final data = {
      'id': memory.id,
      'fact': memory.fact,
      'timestamp': _toTimestamp(memory.timestamp),
    };
    await _withRetry(() => _userDoc.collection('memories').doc(memory.id).set(data));
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    if (_currentUserId == null) return [];
    final snapshot = await _withRetry(() => _userDoc.collection('memories').orderBy('timestamp', descending: true).get());
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Memory(
        id: data['id'],
        fact: data['fact'],
        timestamp: _fromTimestamp(data['timestamp']),
      );
    }).toList();
  }

  @override
  Future<void> deleteMemory(String id) async {
    if (_currentUserId == null) return;
    await _withRetry(() => _userDoc.collection('memories').doc(id).delete());
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
