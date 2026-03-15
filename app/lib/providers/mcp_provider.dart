import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mcp_server.dart';
import '../services/mcp_client_service.dart';
import '../app_config.dart';
import 'data_provider.dart';
import 'ai_provider.dart'; // For toolRegistryProvider

final mcpServerProvider = Provider<McpServerService?>((ref) {
  // When using remote backend, the agent IS the backend — no MCP server needed
  if (AppConfig.useRemoteBackend) return null;

  // Use ref.read to avoid rebuilding (and restarting server) when DataService notifies
  final dataService = ref.read(dataServiceProvider);
  final toolRegistry = ref.watch(toolRegistryProvider);
  final service = McpServerService(dataService, toolRegistry);

  // Start the server
  service.start();

  // Ensure we clean up the server when the provider is disposed/recreated
  ref.onDispose(() {
    service.stop();
  });

  return service;
});

final mcpClientServiceProvider = Provider<McpClientService>((ref) {
  final toolRegistry = ref.watch(toolRegistryProvider);
  final service = McpClientService(toolRegistry);
  // Fire and forget connection start - ideally this should be managed better, 
  // but for "setup" this ensures it starts.
  service.connectToDartMcp();
  return service;
});
