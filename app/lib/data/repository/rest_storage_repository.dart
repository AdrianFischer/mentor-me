import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/node.dart';
import '../../models/ai_models.dart';
import 'storage_repository.dart';

/// StorageRepository implementation backed by the agent's REST API.
/// Flutter becomes a thin client — all data lives in the backend.
class RestStorageRepository implements StorageRepository {
  final String baseUrl;
  final http.Client _client;
  final _dataChangeController = StreamController<void>.broadcast();
  Timer? _sseReconnectTimer;
  bool _disposed = false;

  RestStorageRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  @override
  Stream<void> get onDataChanged => _dataChangeController.stream;

  @override
  Future<void> init() async {
    _connectSSE();
  }

  void dispose() {
    _disposed = true;
    _sseReconnectTimer?.cancel();
    _client.close();
    _dataChangeController.close();
  }

  // ─── SSE for live updates ───

  void _connectSSE() async {
    if (_disposed) return;
    try {
      final request = http.Request('GET', Uri.parse('$baseUrl/events'));
      final response = await _client.send(request);
      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              if (data['type'] == 'data_changed') {
                _dataChangeController.add(null);
              }
            } catch (_) {}
          }
        },
        onDone: () => _scheduleReconnect(),
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _sseReconnectTimer?.cancel();
    _sseReconnectTimer = Timer(const Duration(seconds: 3), _connectSSE);
  }

  // ─── Nodes ───

  @override
  Future<List<Node>> getAllNodes() async {
    final response = await _get('/projects');
    final list = jsonDecode(response.body) as List;
    return list.map((j) => Node.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveNode(Node node) async {
    await _put('/projects/${node.id}', node.toJson());
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    await _delete('/projects/$nodeId');
  }

  // ─── Conversations ───

  @override
  Future<List<Conversation>> getAllConversations() async {
    final response = await _get('/conversations');
    final list = jsonDecode(response.body) as List;
    return list.map((j) => Conversation(
      id: j['id'],
      title: j['title'],
      lastModified: DateTime.parse(j['lastModified']),
      notes: j['notes'],
    )).toList();
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/conversations/${conversation.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': conversation.title, 'notes': conversation.notes}),
    );
    if (response.statusCode == 404) {
      await _post('/conversations', {'title': conversation.title});
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    await _delete('/conversations/$conversationId');
  }

  // ─── Chat History ───

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    if (message.conversationId == null) return;
    await _post('/conversations/${message.conversationId}/messages', {
      'text': message.text,
      'isUser': message.isUser,
    });
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    if (conversationId == null) return [];
    final response = await _get('/conversations/$conversationId/messages');
    final list = jsonDecode(response.body) as List;
    return list.map((j) => ChatMessage(
      id: j['id'],
      text: j['text'],
      isUser: j['isUser'],
      timestamp: DateTime.parse(j['timestamp']),
      conversationId: j['conversationId'],
    )).toList();
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      await _delete('/conversations/$conversationId');
    }
  }

  // ─── Knowledge ───

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    final response = await _get('/knowledge');
    final list = jsonDecode(response.body) as List;
    return list.map((j) => Knowledge(
      id: j['id'],
      content: j['content'],
      createdAt: DateTime.parse(j['createdAt']),
      updatedAt: DateTime.parse(j['updatedAt']),
    )).toList();
  }

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
    await _post('/knowledge', {'content': knowledge.content});
  }

  @override
  Future<void> deleteKnowledge(String id) async {
    await _delete('/knowledge/$id');
  }

  // ─── Memory ───

  @override
  Future<List<Memory>> getAllMemories() async {
    final response = await _get('/memories');
    final list = jsonDecode(response.body) as List;
    return list.map((j) => Memory.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveMemory(Memory memory) async {
    await _post('/memories', {'fact': memory.fact});
  }

  @override
  Future<void> deleteMemory(String id) async {
    await _delete('/memories/$id');
  }

  // ─── HTTP helpers ───

  Future<http.Response> _get(String path) async {
    return _client.get(Uri.parse('$baseUrl$path'));
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    return _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    return _client.put(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _delete(String path) async {
    return _client.delete(Uri.parse('$baseUrl$path'));
  }
}
