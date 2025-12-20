import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mcp_server.dart';
import 'data_provider.dart';

final mcpServerProvider = Provider<McpServerService>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  final service = McpServerService(repository);
  service.start(); 
  return service;
});
