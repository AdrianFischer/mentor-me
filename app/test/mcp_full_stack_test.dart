import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/data/repository/memory_storage_repository.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('MCP Full Stack Test', () {
    late DataService dataService;
    late ToolRegistry toolRegistry;
    late McpServerService serverService;
    late Process bridgeProcess;
    final int port = 8090; // Use a distinct port

    setUp(() async {
      // 1. Setup Server & Data
      final repository = MemoryStorageRepository();
      
      dataService = DataService(repository);
      await dataService.initData();
      
      toolRegistry = ToolRegistry(dataService);
      serverService = McpServerService(dataService, toolRegistry);
      
      await serverService.start(port: port);
    });

    tearDown(() async {
      bridgeProcess.kill();
      await serverService.stop();
    });

    test('Full Flow: Bridge -> Server -> DataService', () async {
      // 2. Spawn Bridge
      // We assume we are running from project root or app depending on context.
      // Since `flutter test` runs from `app`, the bin path is `bin/mcp_bridge.dart`.
      
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
            // Ignore other messages (like logs if any leak to stdout, though bridge logs to stderr)
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

      // A. Initialize (Optional for simple bridge, but good practice)
      // The bridge doesn't intercept initialize, it forwards it.
      // The Server handles it.
      // mcp_dart server might expect 'initialize'.
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
      
      // Parse content to get ID?
      // Result content: [{"type":"text", "text":"{\"result\":\"success\",\"project_id\":\"...\"}"}]
      final contentList = callRes['result']['content'] as List;
      final textContent = contentList.first['text'] as String;
      final resultJson = jsonDecode(textContent);
      expect(resultJson['result'], 'success');
      final projectId = resultJson['project_id'];

      // 4. Verification
      expect(dataService.projects.length, 1);
      expect(dataService.projects.first.title, 'Full Stack Project');
      expect(dataService.projects.first.id, projectId);

      // D. Call Tool: delete_item
      send('tools/call', {
        "name": "delete_item",
        "arguments": {"item_id": projectId}
      });
      final deleteRes = await readResponse(4);
      expect(deleteRes['error'], isNull);

      // Verification
      expect(dataService.projects.isEmpty, isTrue);
    });
  });
}