import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'data_service.dart';
import '../ai_tools/tool_registry.dart';
import '../ai_tools/ai_tool.dart';

class McpServerService {
  final DataService _dataService;
  final ToolRegistry _toolRegistry;
  HttpServer? _server;
  final Map<String, _SseTransport> _sessions = {};

  McpServerService(this._dataService, this._toolRegistry);

  Future<void> start({int port = 8081, int retries = 5}) async {
    if (kIsWeb) {
      print('[MCP] Skipping MCP Server on Web.');
      return;
    }
    if (_server != null) return;

    for (var i = 0; i < retries; i++) {
      final currentPort = port + i;
      try {
        final router = Router();

        // SSE Endpoint (GET)
        router.get('/mcp', (Request request) {
          final transport = _SseTransport(request.requestedUri.path);
          final sessionId = transport.sessionId;
          _sessions[sessionId] = transport;

          transport.onclose = () {
             _sessions.remove(sessionId);
             print('Session $sessionId closed and removed.');
          };

          // Create and connect the MCP Server
          final server = McpServer(
            Implementation(name: 'flutter_app_data', version: '1.0.0'),
          );
          _registerTools(server);
          
          // Connect server to transport
          server.connect(transport);

          // Return SSE Stream
          return Response.ok(
            transport.stream,
            headers: {
              'Content-Type': 'text/event-stream',
              'Cache-Control': 'no-cache',
              'Connection': 'keep-alive',
            },
            context: {'shelf.io.buffer_output': false}, 
          );
        });

        // Message Endpoint (POST)
        router.post('/mcp', (Request request) async {
          final sessionId = request.url.queryParameters['sessionId'];
          if (sessionId == null || !_sessions.containsKey(sessionId)) {
            return Response.notFound('Session not found');
          }

          final transport = _sessions[sessionId]!;
          final body = await request.readAsString();
          
          try {
            final message = mcp.JsonRpcMessage.fromJson(jsonDecode(body));
            transport.handleMessage(message);
            return Response(202);
          } catch (e) {
             return Response.badRequest(body: 'Invalid JSON-RPC');
          }
        });

        final handler = Pipeline()
            .addMiddleware(logRequests())
            .addHandler(router);

        _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, currentPort);
        print('MCP Server listening on http://localhost:$currentPort/mcp');
        
        // Save port for auto-discovery
        try {
          final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
          if (home != null) {
            final configDir = Directory('$home/.assisted_intelligence');
            if (!configDir.existsSync()) configDir.createSync();
            final portFile = File('${configDir.path}/mcp_port');
            portFile.writeAsStringSync(currentPort.toString());
          }
        } catch (e) {
          print('Failed to save MCP port to config: $e');
        }
        return;
      } on SocketException catch (e) {
        if (i < retries - 1) {
          print('Failed to start MCP Server on port $currentPort: $e. Retrying...');
        } else {
          print('Failed to start MCP Server: $e');
          rethrow;
        }
      }
    }
  }

  void _registerTools(McpServer server) {
    // Register 'get_projects' specially if it's not in the registry or needs special handling?
    // Actually, 'get_projects' is NOT in the ToolRegistry (Wait, check file list).
    // I did not see 'get_projects_tool.dart' in the file list I read earlier.
    // I saw 'get_project_tool.dart' (singular).
    // Let's check if 'get_projects' is missing from registry.
    // If so, I should add it or keep it hardcoded for now, but the plan says "Unify".
    // I'll keep the manual one if it's not in registry, but otherwise use registry.

    // Register tools from ToolRegistry
    for (final tool in _toolRegistry.tools) {
       server.registerTool(
         tool.name,
         description: tool.description,
         inputSchema: _mapToInputSchema(tool.inputSchema),
         callback: (args, extra) async {
            try {
               final result = await _toolRegistry.executeTool(tool.name, args);
               return CallToolResult(
                 content: [TextContent(text: jsonEncode(result))],
                 isError: result.containsKey('error') || (result['result'] == 'error'),
               );
            } catch (e) {
               return CallToolResult(
                 content: [TextContent(text: 'Error executing ${tool.name}: $e')],
                 isError: true,
               );
            }
         }
       );
    }
    
    // Explicitly add 'get_projects' if not present (it seems it was manually added in previous version)
    // The previous version had a complex 'get_projects' that serialized the whole tree.
    // Use the existing logic for 'get_projects' if it's not in registry.
    bool hasGetProjects = _toolRegistry.tools.any((t) => t.name == 'get_projects');
    if (!hasGetProjects) {
       server.registerTool(
        'get_projects',
        description: 'Get all projects and their tasks',
        callback: (args, extra) async {
          final projects = _dataService.projects;
          final jsonList = projects.map((p) {
            final pJson = p.toJson();
            pJson['order'] = p.order.isNaN ? 0.0 : p.order;
            if (pJson['tasks'] is List) {
                pJson['tasks'] = (pJson['tasks'] as List).map((t) {
                  final tJson = (t as dynamic).toJson();
                  tJson['order'] = t.order.isNaN ? 0.0 : t.order;
                  if (tJson['subtasks'] is List) {
                    tJson['subtasks'] = (tJson['subtasks'] as List).map((s) {
                      final sJson = (s as dynamic).toJson();
                      sJson['order'] = s.order.isNaN ? 0.0 : s.order;
                      return sJson;
                    }).toList();
                  }
                  return tJson; 
                }).toList();
            }
            return pJson;
          }).toList();
          
          return CallToolResult(
            content: [TextContent(text: jsonEncode(jsonList))],
          );
        },
      );
    }
  }

  ToolInputSchema _mapToInputSchema(Map<String, dynamic> schema) {
     final propsMap = <String, JsonSchema>{};
     final properties = schema['properties'] as Map<String, dynamic>?;
     final requiredList = (schema['required'] as List?)?.map((e) => e.toString()).toList() ?? [];

     if (properties != null) {
        properties.forEach((key, value) {
           final desc = value['description'] as String?;
           final type = value['type'] as String?;
           // Handle basic types
           if (type == 'string') {
              propsMap[key] = JsonSchema.string(description: desc);
           } else if (type == 'number' || type == 'integer') {
              propsMap[key] = JsonSchema.number(description: desc);
           } else if (type == 'boolean') {
              propsMap[key] = JsonSchema.boolean(description: desc);
           } else {
              // Fallback for complex types or unknown
              propsMap[key] = JsonSchema.string(description: desc); 
           }
        });
     }

     return ToolInputSchema(
       properties: propsMap,
       required: requiredList,
     );
  }

  Future<void> restart({int port = 8081, int retries = 5}) async {
    await stop();
    await start(port: port, retries: retries);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _sessions.clear();
  }
}

class _SseTransport implements Transport {
  @override
  final String sessionId;
  final String _endpointPath;
  final StreamController<List<int>> _streamController = StreamController<List<int>>();
  Timer? _heartbeatTimer;

  @override
  void Function()? onclose;

  @override
  void Function(Error error)? onerror;

  @override
  void Function(JsonRpcMessage message)? onmessage;

  _SseTransport(this._endpointPath) : sessionId = const Uuid().v4() {
    // Send endpoint event immediately
    final endpointUrl = '$_endpointPath?sessionId=$sessionId';
    _sendSseEvent('endpoint', endpointUrl);

    // Start heartbeat
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_streamController.isClosed) {
        timer.cancel();
        return;
      }
      // Send comment to keep connection alive
      _streamController.add(utf8.encode(': keep-alive\n\n'));
    });
  }

  Stream<List<int>> get stream => _streamController.stream;

  void handleMessage(JsonRpcMessage message) {
    onmessage?.call(message);
  }

  @override
  Future<void> start() async {
    // No-op for SSE
  }

  @override
  Future<void> send(JsonRpcMessage message, {dynamic relatedRequestId}) async {
    _sendSseEvent('message', jsonEncode(message.toJson()));
  }

  @override
  Future<void> close() async {
    _heartbeatTimer?.cancel();
    await _streamController.close();
    onclose?.call();
  }

  void _sendSseEvent(String event, String data) {
    if (_streamController.isClosed) return;
    final sb = StringBuffer();
    sb.writeln('event: $event');
    sb.writeln('data: $data');
    sb.writeln();
    _streamController.add(utf8.encode(sb.toString()));
  }
}
