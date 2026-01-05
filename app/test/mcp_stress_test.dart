import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/data/repository/memory_storage_repository.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/models/models.dart';

void main() {
  group('MCP Stress Test', () {
    late DataService dataService;
    late ToolRegistry toolRegistry;
    late McpServerService serverService;
    late Process bridgeProcess;
    final int port = 8092; // Use a distinct port

    setUp(() async {
      // Register fallbacks
      registerFallbackValue(const Task(id: 'fallback', title: 'fallback'));
      registerFallbackValue(const Project(id: 'fallback', title: 'fallback'));

      // 1. Setup Server & Data
      final repository = MemoryStorageRepository();
      
      dataService = DataService(repository);
      await dataService.initData();
      
      // Create a default project
      await dataService.addProject("Stress Test Project");
      
      toolRegistry = ToolRegistry(dataService);
      serverService = McpServerService(dataService, toolRegistry);
      
      await serverService.start(port: port);
    });

    tearDown(() async {
      bridgeProcess.kill();
      await serverService.stop();
    });

    test('Stress Test: 10 Adds, 10 Updates, 10 Completions', () async {
      final bridgeScript = 'bin/mcp_bridge.dart';
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

      // Helper to read responses
      final broadcastStream = bridgeProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      Future<Map<String, dynamic>> waitForResponse(int id) async {
        await for (final line in broadcastStream) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line);
            if (json is Map<String, dynamic> && json['id'] == id) {
              return json;
            }
          } catch (e) {
            // ignore
          }
        }
        throw TimeoutException('Response $id not received');
      }
      
      // 1. Add 10 Tasks
      final projectId = dataService.projects.first.id;
      List<String> taskIds = [];
      for (int i = 0; i < 10; i++) {
         send('tools/call', {
           "name": "add_task",
           "arguments": {
             "project_id": projectId,
             "title": "Task $i"
           }
         });
         final res = await waitForResponse(msgId - 1);
         expect(res['error'], isNull, reason: "Failed to add Task $i: ${res['error']}");
         
         final content = (res['result']['content'] as List).first['text'];
         final json = jsonDecode(content);
         taskIds.add(json['task_id']);
      }
      expect(taskIds.length, 10);
      expect(dataService.projects.first.tasks.length, 10);

      // 2. Modify All 10 Tasks
      for (int i = 0; i < 10; i++) {
         send('tools/call', {
           "name": "update_item_name",
           "arguments": {
             "item_id": taskIds[i], 
             "new_name": "Updated Task $i"
           }
         });
         final res = await waitForResponse(msgId - 1);
         expect(res['error'], isNull, reason: "Failed to update Task $i");
      }
      
      // Verify updates
      for (int i = 0; i < 10; i++) {
         final task = dataService.projects.first.tasks.firstWhere((t) => t.id == taskIds[i]);
         expect(task.title, "Updated Task $i");
      }

      // 3. Complete All 10 Tasks
      for (int i = 0; i < 10; i++) {
         send('tools/call', {
           "name": "update_item_status",
           "arguments": {
             "item_id": taskIds[i], 
             "is_completed": true
           }
         });
         final res = await waitForResponse(msgId - 1);
         expect(res['error'], isNull, reason: "Failed to complete Task $i");
      }

      // Verify completion
      for (int i = 0; i < 10; i++) {
         final task = dataService.projects.first.tasks.firstWhere((t) => t.id == taskIds[i]);
         expect(task.isCompleted, isTrue);
      }
    });
  });
}