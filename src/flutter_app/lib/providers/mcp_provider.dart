import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mcp_server.dart';
import 'data_provider.dart';

final mcpServerProvider = Provider<McpServerService>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  final service = McpServerService(dataService);
  service.start(); 
  return service;
});
