import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  // Load environment variables from app/.env
  final env = DotEnv()..load(['app/.env']);
  
  final botToken = env['TELEGRAM_BOT_TOKEN'];
  
  if (botToken == null) {
    stderr.writeln('Error: TELEGRAM_BOT_TOKEN environment variable not set.');
    exit(1);
  }

  // Auto-discover MCP Port
  int mcpPort = 8081;
  try {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final portFile = File('$home/.assisted_intelligence/mcp_port');
      if (portFile.existsSync()) {
        mcpPort = int.parse(portFile.readAsStringSync().trim());
        print('[Bot] Discovered MCP Server on port $mcpPort');
      }
    }
  } catch (e) {
    print('[Bot] MCP discovery failed, using default 8081: $e');
  }

  final username = (await Telegram(botToken).getMe()).username;
  final teledart = TeleDart(botToken, Event(username!));

  teledart.start();
  print('[Bot] Telegram Bot started as @$username');

  teledart.onMessage(keyword: '/start').listen((message) {
    message.reply('Assisted Intelligence Bot active. Send me tasks or voice memos.');
  });

  teledart.onMessage().listen((message) async {
    if (message.text == null && message.voice == null) return;

    final chatId = message.chat.id;
    bool isVoice = message.voice != null;
    final text = message.text ?? '[Voice Memo received]';
    
    print('[Bot] Received message from $chatId: $text');

    try {
      final client = McpClient(
        Implementation(name: 'telegram_bot', version: '1.0.0'),
      );

      final transport = _HttpTransport('http://localhost:$mcpPort/mcp');
      await client.connect(transport);


      if (isVoice) {
         message.reply('I received your voice memo. (STT processing not implemented in this local-first prototype).');
         return;
      }

      // --- Intelligent Response Logic ---
      
      if (text.toLowerCase().contains('tasks') || text.toLowerCase().contains('todo')) {
        final result = await client.callTool(CallToolRequest(name: 'list_todos_by_status', arguments: {'status': 'active'}));
        final content = result.content.first as TextContent;
        final data = jsonDecode(content.text);
        
        if (data['result'] == 'success') {
          final items = data['items'] as List;
          if (items.isEmpty) {
            message.reply('✅ You are all caught up! You have no active tasks at the moment.');
          } else {
            final buffer = StringBuffer('📋 Here are your active tasks:\n\n');
            for (final item in items) {
              buffer.writeln('🔹 ${item['index']}. **${item['title']}**');
              if (item['project'] != null) buffer.writeln('   📂 Project: ${item['project']}');
              if (item['notes'] != null && item['notes'].isNotEmpty) buffer.writeln('   📝 Notes: ${item['notes']}');
              buffer.writeln();
            }
            message.reply(buffer.toString(), parseMode: 'Markdown');
          }
        }
      } else if (text.toLowerCase().startsWith('remember ')) {
        final fact = text.substring(9);
        await client.callTool(CallToolRequest(name: 'save_memory', arguments: {'fact': fact}));
        message.reply('🧠 Memory saved! I will remember: "$fact"');
      } else {
        message.reply('👋 I am your Assisted Intelligence assistant. I can help you manage your tasks and remember important facts.\n\nTry asking:\n• "Show my tasks"\n• "Remember that I like coffee"\n• "What are my todos?"');
      }

    } catch (e) {
      stderr.writeln('[Bot] Error talking to MCP: $e');
      message.reply('Error: Could not connect to the app.');
    }
  });
}

class _HttpTransport implements Transport {
  final String _baseUrl;
  String? _sessionId;
  @override
  String? get sessionId => _sessionId;
  final HttpClient _client = HttpClient();
  final StreamController<JsonRpcMessage> _messageController = StreamController<JsonRpcMessage>.broadcast();

  _HttpTransport(this._baseUrl);

  @override
  void Function()? onclose;
  @override
  void Function(Error error)? onerror;
  @override
  void Function(JsonRpcMessage message)? onmessage;

  @override
  Future<void> start() async {
    final request = await _client.getUrl(Uri.parse(_baseUrl));
    request.headers.set('Accept', 'text/event-stream');
    
    final response = await request.close();
    
    response.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();
        if (line.contains('endpoint?sessionId=')) {
           // We don't really need the endpoint for POST if we know the pattern
           final uri = Uri.parse(data);
           _sessionId = uri.queryParameters['sessionId'];
        } else {
           try {
             final msg = JsonRpcMessage.fromJson(jsonDecode(data));
             onmessage?.call(msg);
           } catch (_) {}
        }
      }
    });
  }

  @override
  Future<void> send(JsonRpcMessage message, {dynamic relatedRequestId}) async {
    if (_sessionId == null) return;
    
    final uri = Uri.parse('$_baseUrl?sessionId=$_sessionId');
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(message.toJson()));
    await request.close();
  }

  @override
  Future<void> close() async {
    _client.close(force: true);
    onclose?.call();
  }
}
