import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mcp_server.dart';
import '../services/mcp_client_service.dart';
import 'data_provider.dart';
import 'ai_provider.dart'; // For toolRegistryProvider

final mcpServerProvider = Provider<McpServerService>((ref) {
  final dataService = ref.watch(dataServiceProvider);
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
