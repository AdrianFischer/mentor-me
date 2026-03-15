import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/data/repository/memory_storage_repository.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/services/conversation_service.dart';
import 'package:flutter_app/services/memory_service.dart';
import 'package:flutter_app/services/knowledge_service.dart';
import 'package:flutter_app/services/agent_session_tracker.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MCP Full Stack Test', () {
    late NodeService nodeService;
    late DataService dataService;
    late ToolRegistry toolRegistry;
    late McpServerService serverService;
    late Process bridgeProcess;
    final int port = 8090; // Use a distinct port

    setUp(() async {
      // 1. Setup Server & Data
      final repository = MemoryStorageRepository();

      nodeService = NodeService(repository);
      await nodeService.initData();

      final conversationService = ConversationService(repository);
      final memoryService = MemoryService(repository);
      final knowledgeService = KnowledgeService(repository);
      final sessionTracker = AgentSessionTracker();

      dataService = DataService(
        nodeService,
        conversationService,
        memoryService,
        knowledgeService,
        sessionTracker,
      );

      toolRegistry = ToolRegistry(nodeService, dataService);
      serverService = McpServerService(nodeService, toolRegistry);

      await serverService.start(port: port, savePortToConfig: false);
    });

    tearDown(() async {
      bridgeProcess.kill();
      await serverService.stop();
    });

    test('Full Flow: Bridge -> Server -> NodeService', () async {
      // 2. Spawn Bridge
      final bridgeScript = 'bin/mcp_bridge.dart';
      if (!File(bridgeScript).existsSync()) {
        fail('Bridge script not found at $bridgeScript. Run from app.');
      }

      bridgeProcess = await Process.start(
        'dart',
        ['run', bridgeScript, 'http://localhost:$port/mcp'],
      );

      // Helper to send JSON-RPC
      int msgId = 1;
      void send(String method, [Map<String, dynamic>? params]) {
        final req = {
          "jsonrpc": "2.0",
          "method": method,
          "params": params ?? {},
          "id": msgId++
        };
        bridgeProcess.stdin.writeln(jsonEncode(req));
      }

      // Helper to read next JSON response
      final broadcastStream = bridgeProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      Future<Map<String, dynamic>> readResponse(int id) async {
        await for (final line in broadcastStream) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line);
            if (json is Map<String, dynamic> && json['id'] == id) {
              return json;
            }
          } catch (e) {
            // Not JSON
          }
        }
        throw TimeoutException('Response not received');
      }

      // Listen to stderr for debugging
      bridgeProcess.stderr.transform(utf8.decoder).listen((data) {
        print('[Bridge Stderr]: $data');
      });

      // 3. Protocol Traffic

      // A. Initialize
      send('initialize', {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "test_client", "version": "1.0"}
      });
      final initRes = await readResponse(1);
      expect(initRes['result'], isNotNull);
      expect(initRes['result']['serverInfo']['name'], 'flutter_app_data');

      // B. List Tools
      send('tools/list');
      final toolsRes = await readResponse(2);
      final tools = toolsRes['result']['tools'] as List;
      expect(tools.any((t) => t['name'] == 'add_project'), isTrue);
      expect(tools.any((t) => t['name'] == 'delete_item'), isTrue);

      // C. Call Tool: add_project
      send('tools/call', {
        "name": "add_project",
        "arguments": {"title": "Full Stack Project"}
      });
      final callRes = await readResponse(3);
      expect(callRes['error'], isNull);

      final contentList = callRes['result']['content'] as List;
      final textContent = contentList.first['text'] as String;
      final resultJson = jsonDecode(textContent);
      expect(resultJson['result'], 'success');
      final projectId = resultJson['project_id'];

      // 4. Verification
      expect(nodeService.rootNodes.length, 1);
      expect(nodeService.rootNodes.first.title, 'Full Stack Project');
      expect(nodeService.rootNodes.first.id, projectId);

      // D. Call Tool: delete_item
      send('tools/call', {
        "name": "delete_item",
        "arguments": {"item_id": projectId}
      });
      final deleteRes = await readResponse(4);
      expect(deleteRes['error'], isNull);

      // Verification
      expect(nodeService.rootNodes.isEmpty, isTrue);
    });
  });
}
