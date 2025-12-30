import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import '../ai_tools/tool_registry.dart';
import '../ai_tools/implementations/mcp_tool_bridge.dart';

class McpClientService {
  final ToolRegistry _toolRegistry;
  Client? _client;

  McpClientService(this._toolRegistry);

  Future<void> connectToDartMcp() async {
    try {
      print('[MCP] Starting Dart MCP Server...');
      
      // Attempt to find dart executable
      String executable = 'dart';
      if (Platform.isMacOS) {
         if (await File('/opt/homebrew/bin/dart').exists()) {
           executable = '/opt/homebrew/bin/dart';
         } else if (await File('/usr/local/bin/dart').exists()) {
            executable = '/usr/local/bin/dart';
         }
      }

      // Use StdioServerParameters to let the transport manage the process
      final parameters = StdioServerParameters(
        command: executable,
        args: ['mcp-server'],
        environment: Platform.environment, // Changed from env to environment
      );

      final transport = StdioClientTransport(parameters);
      
      // Client takes clientInfo as positional arg, capabilities in options
      _client = Client(
        Implementation(name: 'flutter_app_client', version: '1.0.0'),
        options: ClientOptions(
          capabilities: ClientCapabilities(
            experimental: {},
            roots: ClientCapabilitiesRoots(listChanged: true), 
            sampling: null, 
          ),
        )
      );

      print('[MCP] Connecting to MCP Server...');
      await _client!.connect(transport);

      print('[MCP] Connected. Discovering tools...');
      await _discoverAndRegisterTools();

    } catch (e) {
      print('[MCP] Error connecting to Dart MCP Server: $e');
    }
  }

  Future<void> _discoverAndRegisterTools() async {
    if (_client == null) return;

    try {
      final result = await _client!.listTools();
      final tools = result.tools;
      
      print('[MCP] Found ${tools.length} tools.');

      for (var tool in tools) {
        // Convert MCP Tool to AiTool bridge
        final bridge = McpToolBridge(
          tool.name, 
          tool.description ?? '',
          tool.inputSchema.toJson(), 
          this
        );
        _toolRegistry.register(bridge);
        print('[MCP] Registered tool: ${tool.name}');
      }
    } catch (e) {
      print('[MCP] Error listing tools: $e');
    }
  }

  Future<Map<String, dynamic>> executeTool(String name, Map<String, dynamic> args) async {
    if (_client == null) {
      return {'error': 'MCP Client not connected'};
    }
    try {
      // Use CallToolRequest wrapper
      final result = await _client!.callTool(
        CallToolRequest(name: name, arguments: args)
      );
      
      // Convert result content
      final content = result.content;
      final output = content.map((c) {
        if (c is TextContent) {
           return c.text;
        } else if (c is ImageContent) {
           return "[Image Content]"; 
        } else if (c is EmbeddedResource) {
           return "[Embedded Resource]";
        }
        return "";
      }).join("\n");
      
      return {
        'result': 'success',
        'output': output,
        'isError': result.isError
      };
    } catch (e) {
      return {'error': 'Error executing tool $name: $e'};
    }
  }

  void dispose() {
    _client?.close(); 
  }
}
