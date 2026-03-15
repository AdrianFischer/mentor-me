import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mcp_server.dart';
import '../services/mcp_client_service.dart';
import '../app_config.dart';
import 'data_provider.dart';
import 'ai_provider.dart';

final mcpServerProvider = Provider<McpServerService?>((ref) {
  if (AppConfig.useRemoteBackend) return null;

  final nodeService = ref.read(nodeServiceProvider);
  final toolRegistry = ref.watch(toolRegistryProvider);
  final service = McpServerService(nodeService, toolRegistry);

  service.start();

  ref.onDispose(() {
    service.stop();
  });

  return service;
});

final mcpClientServiceProvider = Provider<McpClientService>((ref) {
  final toolRegistry = ref.watch(toolRegistryProvider);
  final service = McpClientService(toolRegistry);
  service.connectToDartMcp();
  return service;
});
